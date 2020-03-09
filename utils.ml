(* Copyright (C) 2015, Thomas Leonard
   See the README file for details. *)

open Lwt.Infix

let log fmt =
  let write msg = Printf.eprintf "%s\n%!" msg in
  Printf.ksprintf write fmt

let error fmt =
  Printf.ksprintf failwith fmt

(** Missing from Unix module API. *)
let fd_of_int (x:int) : Unix.file_descr = Obj.magic x

(** Better error on failure. *)
let int_of_string x =
  try int_of_string x
  with Failure _ -> error "Not an integer: '%S'" x

(** Get a channel for an FD in the given environment variable. *)
let fd_open_env ~mode var =
  let fd =
    try Sys.getenv var |> int_of_string
    with Not_found -> error "$%s not set!" var in
  Lwt_io.of_unix_fd ~mode (fd_of_int fd)

(** Copy from one stream to another until end-of-file. *)
let rec copy src dst =
  Lwt_io.read ~count:40960 src >>= function
  | "" ->
      Lwt.return ()
  | data ->
      Lwt_io.write dst data >>= fun () ->
      copy src dst

(** Read a message from a channel. Abort if we get something else. *)
let expect expected ch =
  Printf.eprintf "Waiting for '%s'... %!" expected;
  Lwt_io.read_line ch >|= function
  | msg when msg = expected -> log "OK"
  | msg ->
      log "ERROR";
      failwith msg
