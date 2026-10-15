exception ParseError of string
(** Converts numbered source lines into typed picture data *)

(** (string * int) -> picture *)
let filter_empty (num, str) =
  if String.length (String.trim str) > 0 then Some (num, String.trim str)
  else None

(* let filter_chr (num, str) = if String.split_on_char ' ' str |> List.length >
   0 then Some (num, str) else None *)

let filter_chr str =
  String.split_on_char ' ' str |> List.filter (fun s -> String.length s > 0)

let number_lines source =
  source |> String.split_on_char ' '
  (* |> List.filter (fun s -> String.length s > 0) *)
  |> List.mapi (fun index text -> (index + 1, text))

(** [words text] is the list of nonempty, space-separated words in [text]. *)
let words text =
  text |> String.trim |> String.split_on_char ' '
  |> List.filter (fun word -> word <> "")

(* let rec parse_transform_entries lines = match lines with | [] -> ([], []) |
   ((_, text) as line) :: rest -> match words text with | [] ->
   parse_transform_entries rest | ["end"] -> ([], line :: rest) | _ -> let
   entry, after_entry = parse_transform_entries line rest in let *)

let match_number num line_num =
  if float_of_string_opt num < Some 0.0 then
    raise
      (ParseError
         ("Line " ^ string_of_int line_num ^ ": Dimension must be Positive"))
  else if float_of_string_opt num == None then
    raise
      (ParseError ("Line " ^ string_of_int line_num ^ ": Invalid Dimension"))
  else float_of_string num

let match_color color =
  match color with
  | "black" -> Some Picture.Black
  | "white" -> Some Picture.White
  | "gray" -> Some Picture.Gray
  | "red" -> Some Picture.Red
  | "orange" -> Some Picture.Orange
  | "yellow" -> Some Picture.Yellow
  | "green" -> Some Picture.Green
  | "blue" -> Some Picture.Blue
  | "purple" -> Some Picture.Purple
  | "pink" -> Some Picture.Pink
  | "brown" -> Some Picture.Brown
  | "navy" -> Some Picture.Navy
  | "teal" -> Some Picture.Teal
  | "gold" -> Some Picture.Gold
  | "cream" -> Some Picture.Cream
  | _ -> None

let rec parse_text_content (content : string list) str =
  match content with
  | [] -> str
  | head :: tail -> parse_text_content tail (str ^ " " ^ head)

let rec parse_entries (lines : (int * string) list) =
  match lines with
  | [] -> ([], [])
  | ((_, text) as line) :: rest -> (
      match words text with
      | [] -> parse_entries rest
      | [ "end" ] -> ([], line :: rest)
      | _ ->
          let entry, after_entry = parse_entry line rest in
          let later_entries, remaining = parse_entries after_entry in
          (entry :: later_entries, remaining))

and parse_entry (number, text) rest =
  match (number, words text) with
  | num, [ "canvas"; width; height; background ] ->
      ( Picture.Canvas
          {
            Picture.width = match_number width num;
            Picture.height = match_number height num;
            Picture.background = match_color background;
          },
        rest )
  | num, [ "circle"; center_x; center_y; radius; fill ] ->
      ( Picture.Circle
          {
            Picture.center_x = match_number center_x num;
            Picture.center_y = match_number center_y num;
            Picture.radius = match_number radius num;
            Picture.fill =
              (if match_color fill == None then
                 raise
                   (ParseError "Circle needs to be filled with a proper color")
               else match_color fill);
          },
        rest )
  | num, [ "rectangle"; x; y; width; height; fill ] ->
      ( Picture.Rectangle
          {
            Picture.x = match_number x num;
            Picture.y = match_number y num;
            Picture.width = match_number width num;
            Picture.height = match_number height num;
            Picture.fill =
              (if match_color fill == None then
                 raise
                   (ParseError
                      "Rectangle needs to be filled with a proper color")
               else match_color fill);
          },
        rest )
  | num, [ "line"; x1; y1; x2; y2; fill; width ] ->
      ( Picture.Line
          {
            Picture.x1 = match_number x1 num;
            Picture.y1 = match_number y1 num;
            Picture.x2 = match_number x2 num;
            Picture.y2 = match_number y2 num;
            Picture.color =
              (if match_color fill == None then
                 raise
                   (ParseError "Line needs to be filled with a proper color")
               else match_color fill);
            Picture.width = match_number width num;
          },
        rest )
  | num, "text" :: x :: y :: size :: color :: contents ->
      ( Picture.Text
          {
            Picture.x = match_number x num;
            Picture.y = match_number y num;
            Picture.size = match_number size num;
            Picture.color =
              (if match_color color == None then
                 raise
                   (ParseError "Line needs to be filled with a proper color")
               else match_color color);
            Picture.contents = parse_text_content contents "";
          },
        rest )
  | num, "transform" :: transform_type ->
      parse_transform num transform_type rest
  | num, "repeat" :: count :: param -> parse_repeat count num param rest
  | num, _ -> raise (ParseError "Invalid shape")

and parse_transform num translate_type lines =
  match parse_entries lines with
  | _, [] -> raise (ParseError "no")
  | elements, _end_line :: after_end -> (
      match translate_type with
      | [ "translate"; dx; dy ] ->
          ( Picture.Translate
              {
                dx = match_number dx num;
                dy = match_number dy num;
                entries = elements;
              },
            after_end )
      | [ "rotate"; degrees ] ->
          ( Picture.Rotate
              { degrees = match_number degrees num; entries = elements },
            after_end )
      | [ "scale"; factor ] ->
          ( Picture.Scale
              { factor = match_number factor num; entries = elements },
            after_end )
      | _ -> raise (ParseError "Invalid transformation"))

and parse_repeat i line_num param rest =
  let tranform = parse_transform line_num param rest in
  ( Picture.Repeat { count = match_number i line_num; transform = fst tranform },
    snd tranform )

let parse_exn source =
  match parse_entries source with
  | entries, [] -> entries
  | _, (number, _) :: _ -> raise (ParseError "nooo")

(* let rec super_parser lines = match lines with | [] -> ([], []) | ((_, text)
   as line) :: rest -> match words text with | [] -> super_parser rest | ["end"]
   -> ([], line :: rest) | _ -> let entry, after_entry = super_parse_entry line
   rest in let later_enrties, remaining = super_parse_entry after_entry in
   (entry :: later_enrties, remaining) and super_parse_entry (number, text) rest
   = match words text with | ["translate"; dx; dy] -> | ["transform"] *)

(* (num, ["rectangle"; x; y; width; height; fill]) :: tail -> ({ Picture.x =
   match_number x num; Picture.y= match_number y num; Picture.width =
   match_number width num; Picture.height = match_number height num;
   Picture.fill = if (match_color fill == None) then raise (ParseError "Shape
   needs to be filled with a proper color") else match_color fill } :: elements
   ) *)
(* 
let parser_result input =
  match parser input with
  | exception ParseError msg -> Error msg
  | _ -> Ok (parser input) *)
