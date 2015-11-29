(* Copyright (C) 2015, Thomas Leonard
   See the README file for details. *)

(** This should be compiled and installed in dom0 as e.g. /usr/local/bin/test-mirage-dom0
    That path should also be placed in /etc/qubes-rpc/talex5.TestMirage
    and a policy allowing it added to /etc/qubes-rpc/policy/talex5.TestMirage *)

open Lwt.Infix

let to_dev = Lwt_io.stdout
let from_dev = Lwt_io.stdin
let vm_kernels = "/var/lib/qubes/vm-kernels"

let (/) = Filename.concat

let timeout s =
  Lwt_unix.sleep s >|= fun () -> failwith "Timeout!"

let rec copyn src dst = function
  | 0 -> Lwt.return ()
  | n ->
      Lwt_io.read ~count:(min 40960 n) src >>= function
      | "" -> failwith "Unexpected end-of-file"
      | data ->
          Lwt_io.write dst data >>= fun () ->
          copyn src dst (n - String.length data)

let receive_image image_path =
  Lwt_io.read_line from_dev >>= fun size ->
  let size = Utils.int_of_string size in
  Lwt_io.with_file ~flags:Unix.[O_CREAT; O_WRONLY; O_TRUNC] ~mode:Lwt_io.output image_path (fun to_img ->
    copyn from_dev to_img size
  )

let error fmt = Printf.ksprintf failwith fmt

let re_valid_name = "^[A-Za-z0-9][-.A-Za-z0-0]*$"
let kernel_image_path vm_name =
  let re = Str.regexp re_valid_name in
  if not (Str.string_match re vm_name 0) then
    error "VM name %S does not match regexp %S" vm_name re_valid_name;
  let dir = vm_kernels / vm_name in
  let test_file = dir / "test-mirage-ok" in
  if not (Sys.file_exists test_file) then
    error "To allow uploading this kernel, touch %S in dom0" test_file;
  dir / "vmlinuz"

let main () =
  Lwt_io.write_line to_dev "Ready" >>= fun () ->
  Lwt_io.read_line from_dev >>= fun vm_name ->
  let image_path = kernel_image_path vm_name in
  Lwt.pick [receive_image image_path; timeout 5.0] >>= fun () ->
  Lwt_io.write_line to_dev "Booting" >>= fun () ->
  Lwt_io.flush to_dev >>= fun () ->
  Unix.dup2 Unix.stdout Unix.stderr;
  let start_cmd = ("", [| "qvm-start"; vm_name |]) in
  let stop_cmd = ("", [| "qvm-kill"; vm_name |]) in
  Lwt_process.exec ~stdin:`Close ~stdout:`Keep ~stderr:(`FD_copy Unix.stdout) stop_cmd >>= fun _status ->
  Lwt_process.exec ~stdin:`Close ~stderr:(`FD_copy Unix.stdout) start_cmd >>= function
  | Unix.WEXITED 0 ->
      Printf.printf "Connecting to %s console...\n%!" vm_name;
      Unix.execv "/usr/bin/sudo" [| "/usr/bin/sudo"; "xl"; "console"; vm_name |]
  | _ ->
      let log_file = Printf.sprintf "/var/log/xen/console/guest-%s.log" vm_name in
      Printf.printf "qvm-start failed; showing tail of %s\n%!" log_file;
      Unix.execv "/usr/bin/tail" [| "/usr/bin/tail"; log_file |]

let report_error ex =
  let msg =
    match ex with
    | Failure msg -> msg
    | ex -> Printexc.to_string ex in
  Lwt_io.write_line to_dev msg >|= fun () ->
  exit 1

let () =
  Lwt_main.run (Lwt.catch main report_error)
