(*
 * Copyright (C) Citrix Systems Inc.
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
open Version

exception Missing_param of string

let command uri username password filename =
  let rc = Options.read_rc () in
  let required name = function
  | None ->
    if List.mem_assoc name rc
    then List.assoc name rc
    else raise (Missing_param name)
  | Some x -> x in
  try
    let username = required "username" username in
    let password = required "password" password in
    let uri = required "server" uri in
    let filename = match filename with
    | None -> raise (Missing_param "path")
    | Some x -> x in
    let open Lwt in
    let t =
      let module M = Bootable_disk.Make(Ramdisk) in
      M.write ~kernel:filename ~id:"boot_disk" >>= fun device ->
      let module Uploader = Disk_upload.Make(Ramdisk) in
      Uploader.upload ~pool:uri ~username ~password ~device >>= fun vdi ->
      Printf.printf "%s\n%!" vdi;
      return () in
    `Ok (Lwt_main.run t)
  with Missing_param x ->
    `Error(true, "Please supply a unikernel filename using the --path option")
    
(* Command-line parsing *)
open Cmdliner

let _common_options = "COMMON OPTIONS"

let project_url = "https://github.com/djs55/xe-unikernel-upload"

let help = [
 `S _common_options;
 `P "These options are common to all commands.";
 `S "MORE HELP";
 `P "Use `$(mname) $(i,COMMAND) --help' for help on a single command."; `Noblank;
 `S "BUGS"; `P (Printf.sprintf "Check bug reports at %s" project_url);
]


let cmd =
  let doc = "Upload a unikernel" in
  let uri =
    let doc = "URI for the pool." in
    Arg.(value & opt (some string) None & info [ "uri" ] ~doc) in 
  let username =
    let doc = "Username" in
    Arg.(value & opt (some string) None & info [ "username" ] ~doc) in
  let password =
    let doc = "Password" in
    Arg.(value & opt (some string) None & info [ "password" ] ~doc) in
  let filename =
    let doc = "Path to the Unikernel binary." in
    Arg.(value & opt (some file) None & info [ "path" ] ~doc) in
  let man = [
    `S "DESCRIPTION";
    `P "Wrap a unikernel in a bootable disk image and upload to a XenServer pool.";
    `S "RETURN VALUE";
    `P "On success the program prints the uuid of the VDI containing the image to stdout.";
    `S _common_options;
    `P "These options are common to all services.";
    `S "BUGS";
    `P ("Check bug reports at " ^ project_url);
  ] in
  Term.(ret (pure command $ uri $ username $ password $ filename)),
  Term.info Sys.argv.(0) ~version ~sdocs:_common_options ~doc ~man

let _ =
  match Term.eval cmd with
  | `Error _ -> exit 1
  | _ -> exit 0
