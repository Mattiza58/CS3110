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

(** [securities market] contains the security names in CSV header order. *)
let securities market = market.securities

(** [rows market] contains the dated price rows in file order. The backtest
    engine can traverse these rows and supply only the current row to a
    strategy. *)
let rows market = market.rows

(** [parse_price price] is the integer-cent amount represented by [price].
    Raises [MarketError] if [price] is not a nonnegative two-decimal dollar
    amount in the integer range. Valid market input supplies a strictly positive
    price. *)
let parse_price price =
  match Money.convert_cents price with
  | Ok cents -> cents
  | Error message -> raise (MarketError (message ^ ": " ^ price))

(** [parse_row securities fields] associates a row's date and prices with the
    header's [securities], preserving header order. Raises [MarketError] if the
    field count or a price cannot be parsed. Requires unique security names and
    a valid date in the first field, as guaranteed by valid market input. *)
let parse_row securities = function
  | date :: prices when List.length prices = List.length securities ->
      { date; prices = List.combine securities (List.map parse_price prices) }
  | _ -> raise (MarketError "A price row does not match the header")

(** [load filename] reads a market file with the OCaml CSV parser. The file must
    satisfy the assignment's valid-input rules. Dates and securities retain file
    order, and prices are converted to integer cents using [Money]. Returns
    [Error message] if the file cannot be opened or read, or parsing fails. This
    function does not print messages or exit the program. *)
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
