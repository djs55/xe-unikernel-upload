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

(* TODO: automatically resize the image based on the kernel size *)
open Lwt

let (>>|=) m f = m >>= function
| `Error (`Unknown x) -> fail (Failure x)
| `Error `Unimplemented -> fail (Failure "Unimplemented")
| `Error `Is_read_only -> fail (Failure "Is_read_only")
| `Error `Disconnected -> fail (Failure "Disconnected")
| `Ok x -> f x