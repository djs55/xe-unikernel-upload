(*
 * Copyright (C) 2006-2009 Citrix Systems Inc.
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

let parse_lines ls =
  let rec inner ls cur =
    try 
      match ls with
        ""::ls -> inner ls cur  (* skip blank lines *)
      |	l::ls ->
	  let colon = String.index l '=' in
	  let token = String.sub l 0 colon in
	  let value = String.sub l (colon+1) (String.length l - colon - 1) in
	  inner ls ((token,value)::cur)
      | _ -> cur
    with Not_found -> 
      Printf.fprintf stderr "Error parsing rc file. No defaults loaded\n";
      []
  in
  inner ls []
    
let read_rc () =
  try
    let home = Sys.getenv "HOME" in
    let rc_file = open_in (home^"/.xe") in
    let rec getlines cur =
      try 
	let line = input_line rc_file in
	getlines (line::cur)
      with
	_ -> cur
    in
    let lines = getlines [] in
    parse_lines lines
  with
    _ -> []
