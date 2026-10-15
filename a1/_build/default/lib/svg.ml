(** Contains typed picture data into SVG text *)

let match_color (background : Picture.color) =
  match background with
  | Black -> "#111111"
  | White -> "#ffffff"
  | Gray -> "#808080"
  | Red -> "#FF0000"
  | Orange -> "#f77f00"
  | Yellow -> "#fcbf49"
  | Green -> "#2a9d8f"
  | Blue -> "#277da1"
  | Purple -> "#7b2cbf"
  | Pink -> "#e76f91"
  | Brown -> "#8d6e63"
  | Navy -> "#091226"
  | Teal -> "#008080"
  | Gold -> "#d9a441"
  | Cream -> "#fff1b0"

let convert_float num =
  if Float.equal (Float.round num) num then string_of_int (int_of_float num)
  else string_of_float num

let match_background (background : Picture.color option) =
  match background with
  | Some background -> background
  | None -> Black

let render_rectangle (picture : Picture.picture) =
  if picture.background == None then ""
  else
    "<rect x='0' y ='0' width ='"
    ^ convert_float picture.width
    ^ "' height ='"
    ^ convert_float picture.height
    ^ "' fill ='"
    ^ match_color (match_background picture.background)
    ^ "' />"

(** Couldn't finish :( )*)
let rec render_elements (elements : Picture.elements list) svg_text =
  match elements with
  | [] -> svg_text
  | Canvas element :: tail ->
      render_elements tail
        (svg_text ^ "<svg xmlns='http://www.w3.org/2000/svg' width='"
        ^ convert_float element.width
        ^ "' height='"
        ^ convert_float element.height
        ^ "' viewBox = '0 0 "
        ^ convert_float element.width
        ^ " "
        ^ convert_float element.height
        ^ "'>" ^ render_rectangle element)
  | Circle element :: tail ->
      render_elements tail
        (svg_text ^ " <circle cx='"
        ^ convert_float element.center_x
        ^ "' cy='"
        ^ convert_float element.center_y
        ^ "' r='"
        ^ convert_float element.radius
        ^ "' fill = '"
        ^ match_color (match_background element.fill)
        ^ "' /> ")
  | Rectangle element :: tail ->
      render_elements tail
        (svg_text ^ "<rect x='" ^ convert_float element.x ^ "' y='"
       ^ convert_float element.y ^ "' width =\n    '"
        ^ convert_float element.width
        ^ "' height ='"
        ^ convert_float element.height
        ^ "' fill ='"
        ^ match_color (match_background element.fill)
        ^ "' /> ")
  | Line element :: tail ->
      render_elements tail
        (svg_text ^ "<line x1='" ^ convert_float element.x1 ^ "' y1 ='"
       ^ convert_float element.y1 ^ "' x2 ='" ^ convert_float element.x2
       ^ "' y2 = '" ^ convert_float element.y2 ^ "' stroke ='"
        ^ match_color (match_background element.color)
        ^ "' stroke-width = '"
        ^ convert_float element.width
        ^ "' /> ")
  | Text element :: tail ->
      render_elements tail
        (svg_text ^ "<text x='" ^ convert_float element.x ^ "' y='"
       ^ convert_float element.y
       ^ "' font-family= 'sans-serif' font-size = '42' text-anchor = 'middle' \
          fill ='"
        ^ match_color (match_background element.color)
        ^ "'> " ^ element.contents ^ "</text>")
  | Translate element :: tail ->
      render_elements tail
        (svg_text ^ "<g transform ='translate(" ^ convert_float element.dx ^ " "
       ^ convert_float element.dy ^ " )' >"
        ^ render_elements element.entries ""
        ^ "</g>")
  | Rotate element :: tail ->
      render_elements tail
        (svg_text ^ "<g transform ='rotate("
        ^ convert_float element.degrees
        ^ ")' >"
        ^ render_elements element.entries ""
        ^ "</g>")
  | Scale element :: tail ->
      render_elements tail
        (svg_text ^ "<g transform 'scale= ("
        ^ convert_float element.factor
        ^ ")' >"
        ^ render_elements element.entries ""
        ^ "</g>")
  | Repeat element :: tail -> ""

let render elements = render_elements elements "" ^ " </svg>"

(* let render (picture : Picture.picture) = "<svg
   xmlns='http://www.w3.org/2000/svg' width='" ^ convert_float picture.width ^
   "' height='" ^ convert_float picture.height ^ "' viewBox = '0 0 " ^
   convert_float picture.width ^ " " ^ convert_float picture.height ^ "'>" ^
   render_rectangle picture ^ render_elements pictur"" ^ "</svg>" *)
