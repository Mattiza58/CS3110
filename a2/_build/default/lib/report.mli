(** Presentation of completed Backtest results, without recomputing trades or
    portfolio values. *)

val render : Backtest.t -> string
(** Render the complete final summary, including strategy, period, initial cash,
    final cash, positive holdings, final value, and percentage return. Money and
    return have two decimal places. The string ends with a newline. No I/O. *)

val write : string -> Backtest.t -> (unit, string) result
(** [write filename result] writes the exact [date,value] header and one row per
    simulation date, in order, using the recorded post-order portfolio values.
    Values have two decimal places with no dollar signs or separators. Returns
    an error identifying the output file if it cannot be opened or written. An
    existing output file is overwritten. *)
