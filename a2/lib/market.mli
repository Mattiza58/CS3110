(** Historical closing prices read from a market CSV file. *)

type row = {
  date : string;
  prices : (string * int) list;
}
(** One date's closing prices, in integer cents. Prices appear in the same order
    as the security names in the CSV header. *)

type t
(** A market's security names and dated price rows. Its representation is
    hidden; clients obtain market values through [load]. *)

val load : string -> (t, string) result
(** [load filename] reads a market file with the OCaml CSV parser. The file must
    satisfy the assignment's valid-input rules. Dates and securities retain file
    order, and prices are converted to integer cents using [Money]. Returns
    [Error message] if the file cannot be opened or read, or parsing fails. This
    function does not print messages or exit the program. *)

val securities : t -> string list
(** [securities market] contains the security names in CSV header order. *)

val rows : t -> row list
(** [rows market] contains the dated price rows in file order. The backtest
    engine can traverse these rows and supply only the current row to a
    strategy. *)
