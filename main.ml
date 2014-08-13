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

let command uri username password filename =
  let open Lwt in
  let t =
    Boot_disk.upload ~pool:uri ~username ~password ~kernel:filename
    >>= fun vdi ->
    return () in
  `Ok (Lwt_main.run t)

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
    Arg.(value & opt string "https://localhost/" & info [ "URI" ] ~doc) in 
  let username =
    let doc = "Username" in
    Arg.(value & opt string "root" & info [ "USERNAME" ] ~doc) in
  let password =
    let doc = "Password" in
    Arg.(value & opt string "password" & info [ "PASSWORD" ] ~doc) in
  let filename =
    let doc = "Path to the Unikernel binary." in
    Arg.(value & opt file "unikernel" & info [ "PATH" ] ~doc) in
  let man = help in
  Term.(ret (pure command $ uri $ username $ password $ filename)),
  Term.info Sys.argv.(0) ~version ~sdocs:_common_options ~doc ~man

let _ =
  match Term.eval cmd with
  | `Error _ -> exit 1
  | _ -> exit 0
