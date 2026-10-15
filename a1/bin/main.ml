(* let input = print_endline "Input arg: "; read_line

   let output = print_endline "Output arg: "; read_line *)

(* let argCheck = if Array.length Sys.argv != 3 then ( Printf.eprintf "Usage: ";
   exit 1) else Printf.printf "Arg1: %s, Arg2 %s" Sys.argv.(1) Sys.argv.(2) *)

(* let print_num_lines = match A1.Generator.read_numbered_lines Sys.argv.(1)
   with | Ok value -> List.iter (fun (line_number, line) -> Printf.printf "%d:\n
   %s\n" line_number line) value | Error err -> Printf.eprintf "Error:\n
   Nonexistent File Name\n" *)

(* let print_str list = List.iter (fun x -> Printf.printf "%s " x) list *)

(* let output = A1.Parser.parser (match A1.Generator.read_numbered_lines
   Sys.argv.(1) with | Ok value -> value | Error err -> Printf.eprintf "e"; exit
   1) |> A1.Svg.render |> A1.Generator.write_svg "examples/canvas.svg" *)

(* let print_svg = print_endline (A1.Svg.render (A1.Parser.parser (match
   A1.Generator.read_numbered_lines Sys.argv.(1) with | Ok value -> value |
   Error err -> Printf.eprintf "e"; exit 1))) *)

(* let output = A1.Generator.write_svg (A1.Svg.render (A1.Parser.parser (match
   A1.Generator.read_numbered_lines Sys.argv.(1) with | Ok value -> value |
   Error err -> Printf.eprintf "Error: Invalid "; exit 1))) Sys.argv.(2) *)

(* let print = match (A1.Parser.number_lines (match
   A1.Generator.read_numbered_lines Sys.argv.(1) with | Ok value -> value |
   Error err -> Printf.eprintf "Error: Invalid "; exit 1))) with | (i, str) ::
   tail -> print_endline str | [] -> print_endline "nothing" *)

let output =
  A1.Generator.write_svg
    (A1.Svg.render
       (A1.Parser.parse_exn
          (match A1.Generator.read_numbered_lines Sys.argv.(1) with
          | Ok value -> value; 
          | Error err ->
              Printf.eprintf "Error: Invalid ";
              exit 1)))
    Sys.argv.(2)


let print_out = A1.Generator.print_lines (match A1.Generator.read_numbered_lines (Sys.argv.(1)) with | 
Ok value -> value |
Error err -> 
   Printf.eprintf "Error : Invalid";
   exit 1)



(* let out = A1.Generator.write_svg (A1.Svg.render (A1.Parser.parse_exn
   Sys.argv.(1))) Sys.argv.(2) *)

(* with | Ok value -> value | Error err -> Printf.eprintf "Error"; exit 1 *)

(* let print_modified_num_lines = match A1.Generator.read_numbered_lines
   Sys.argv.(1) with | Ok value -> List.iter (fun (line_number, str) ->
   Printf.printf "%d: %s\n" line_number (String.concat ", " str))
   (A1.Parser.parser value) | Error err -> Printf.eprintf "Error: Nonexistent
   File Name\n" *)
