exception WriteError of string
(** Reads .pic files, pareses it, generates an SVG, and writes an .svg file*)

let read_numbered_lines input_file =
  let lines =
    try Ok (In_channel.with_open_bin input_file In_channel.input_lines)
    with Sys_error msg -> Error msg
  in
  match lines with
  | Ok value -> Ok (List.mapi (fun index line -> (index + 1, line)) value)
  | Error msg -> Error msg

let print_lines lines =
  List.iter (fun (line, str) -> Printf.printf "%d: %s" line str) lines

let write_svg svg_text output_filename =
  try
    Out_channel.with_open_text output_filename (fun channel ->
        output_string channel svg_text)
  with WriteError err -> Printf.eprintf "Could not open file"

(* let read_numbered_lines input_file = In_channel.with_open_text input_file
   In_channel.input_lines in List.mapi *)
