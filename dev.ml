(* Copyright (C) 2015, Thomas Leonard
   See the README file for details. *)

(** This should be run in your development VM as:
    qrexec-client-vm dom0 talex5.TestMirage dev.native mir-image.xen *)

open Lwt.Infix
let log = Utils.log

let to_dom0 = Lwt_io.stdout
let from_dom0 = Lwt_io.stdin
let to_human = Utils.fd_open_env ~mode:Lwt_io.output "SAVED_FD_1"
let from_human = Utils.fd_open_env ~mode:Lwt_io.input "SAVED_FD_0"

let upload image_path =
  (* Wait for "Ready". Connection sometimes seems to hang if we send first. *)
  Utils.expect "Ready" from_dom0 >>= fun () ->
  (* Copy the image to the remote VM *)
  Lwt.async (fun () ->
    Lwt_io.file_length image_path >>= fun size ->
    log "Uploading '%s' (%Ld bytes)" image_path size;
    Lwt_io.with_file ~flags:Unix.[O_RDONLY] ~mode:Lwt_io.input image_path (fun src ->
      Lwt_io.write_line Lwt_io.stdout (Int64.to_string size) >>= fun () ->
      Utils.copy src Lwt_io.stdout
    )
  );
  Utils.expect "Booting" from_dom0 >>= fun () ->
  Lwt.join [
    Utils.copy from_human to_dom0;
    Utils.copy from_dom0 to_human;
  ]

let () =
  match Sys.argv with
  | [| _; image |] -> Lwt_main.run (upload image)
  | _ -> failwith "Usage: test-mirage mir-image.xen"
