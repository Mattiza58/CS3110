type row = {
  date : string;
  prices : (string * int) list;
}

(* Rows retain file order, and prices retain header order. Every price is in
   integer cents. The representation is hidden by market.mli. *)
type t = {
  securities : string list;
  rows : row list;
}

exception MarketError of string

let securities market = market.securities
let rows market = market.rows

let parse_price price =
  match Money.convert_cents price with
  | Ok cents -> cents
  | Error message -> raise (MarketError (message ^ ": " ^ price))

let parse_row securities = function
  | date :: prices when List.length prices = List.length securities ->
      { date; prices = List.combine securities (List.map parse_price prices) }
  | _ -> raise (MarketError "A price row does not match the header")

let load filename =
  try
    match Csv.load filename with
    | ("date" :: (_ :: _ as securities)) :: (_ :: _ as data) ->
        Ok { securities; rows = List.map (parse_row securities) data }
    | _ ->
        raise (MarketError "Expected a date header, securities, and price rows")
  with
  | Sys_error message | MarketError message ->
      Error (Printf.sprintf "Cannot load market file %S: %s" filename message)
  | Csv.Failure (record, field, message) ->
      Error
        (Printf.sprintf "Cannot parse market file %S at record %d, field %d: %s"
           filename record field message)
