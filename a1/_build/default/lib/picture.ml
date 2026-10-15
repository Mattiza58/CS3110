(** Contains typed representations of Picture This pictures*)

type color =
  | Black
  | White
  | Gray
  | Red
  | Orange
  | Yellow
  | Green
  | Blue
  | Purple
  | Pink
  | Brown
  | Navy
  | Teal
  | Gold
  | Cream

type circle = {
  center_x : float;
  center_y : float;
  radius : float;
  fill : color option;
}

type rectangle = {
  x : float;
  y : float;
  width : float;
  height : float;
  fill : color option;
}

type line = {
  x1 : float;
  y1 : float;
  x2 : float;
  y2 : float;
  color : color option;
  width : float;
}

type text = {
  x : float;
  y : float;
  size : float;
  color : color option;
  contents : string;
}

type picture = {
  width : float;
  height : float;
  background : color option;
}

type elements =
  | Canvas of picture
  | Rectangle of rectangle
  | Circle of circle
  | Line of line
  | Text of text
  | Translate of {
      dx : float;
      (* Can be negative *)
      dy : float;
      (* Can be negative *)
      entries : elements list;
    }
  | Rotate of {
      degrees : float;
      (* Can be negative *) entries : elements list;
    }
  | Scale of {
      factor : float;
      entries : elements list;
    }
  | Repeat of {
      count : float;
      transform : elements;
    }

(* type translate = { dx : float; (* Can be negative *) dy : float; (* Can be
   negative *) entries : elements list; }

   type rotate = { degrees : float; (* Can be negative *) entries : elements
   list; }

   type scale = { factor : float; entries : elements list; }

   type transform = | Translate of translate | Rotate of rotate | Scale of
   scale *)

(* type translate = { dx : float; (* Can be negative *) dy : float; (* Can be
   negative *) } *)
