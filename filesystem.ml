(*
 * Copyright (C) 2011-2013 Citrix Inc
 *
 * Permission to use, copy, modify, and distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *)

(* A FAT filesystem containing the grub configuration + kernel *)

module Make(B: V1_LWT.BLOCK) = struct
  open Lwt

  let write ~kernel ~device =
    Lwt_unix.LargeFile.stat kernel >>= fun stats ->
    if stats.Lwt_unix.LargeFile.st_size > Int64.(mul (mul 14L 1024L) 1024L)
    then failwith "We only support kernels < 14MiB in size";
    let disk_length_bytes = Int32.(mul (mul 16l 1024l) 1024l) in
    let disk_length_sectors = Int32.(div disk_length_bytes 512l) in

    let start_sector = 2048l in
    let length_sectors = Int32.sub disk_length_sectors start_sector in
    let length_bytes = Int32.(mul length_sectors 512l) in

    let module FS = Fat.Fs.Make(B)(Io_page) in

    let open Fat in
    let open S in
    let (>>*=) m f = m >>= function
      | `Error (`Block_device e) -> fail (Failure (Fs.string_of_block_error e))
      | `Error e -> fail (Failure (Fs.string_of_filesystem_error e))
      | `Ok x -> f x in

    FS.connect device >>*= fun fs ->
    FS.format fs (Int64.of_int32 length_bytes) >>*= fun () ->

    let kernel_path = "/kernel" in
    let bootloader_list = [ "boot"; "isolinux"; "isolinux.cfg" ] in
    let bootloader_path = String.concat "/" bootloader_list in
    (* mkdir -p *)
    Lwt_list.fold_left_s (fun dir x ->
      let x' = Filename.concat dir x in
      FS.mkdir fs x' >>*= fun () ->
      return x'
    ) "/" (List.(rev (tl (rev bootloader_list))))
    >>= fun _ ->
    FS.create fs bootloader_path >>*= fun () ->

    let bootloader_string = String.concat "\n" [
      "default mirage";
      "prompt 1";
      "timeout 50";
      "";
      "label mirage";
      "  kernel /kernel";
    ] in
    let bootloader_cstruct = Cstruct.create (String.length bootloader_string) in
    Cstruct.blit_from_string bootloader_string 0 bootloader_cstruct 0 (Cstruct.len bootloader_cstruct);
    FS.write fs bootloader_path 0 bootloader_cstruct >>*= fun () ->

    (* Write the kernel image *)
    FS.create fs kernel_path >>*= fun () ->
    let len = Int64.to_int stats.Unix.LargeFile.st_size in
    let buffer = Cstruct.create len in
    Lwt_unix.openfile kernel [ Unix.O_RDONLY ] 0 >>= fun fd ->
    Lwt_cstruct.(complete (read fd) buffer) >>= fun () ->
    FS.write fs kernel_path 0 buffer >>*= fun () ->
    Lwt_unix.close fd

end
