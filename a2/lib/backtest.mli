(** Strategy-independent date-by-date simulation. Accounting is delegated to
    Portfolio; this module performs no file or terminal I/O. *)

type snapshot = private {
  date : string;
  portfolio : Portfolio.t;
  value : int;
  orders : Order.t list;
  outcomes : Order.outcome list;
}
(** The portfolio and value after all orders for [date] have been processed at
    that date's prices. Outcomes correspond to orders in the same order. Fields
    are readable, but clients cannot construct or modify snapshots. *)

type t = private {
  strategy : string;
  initial_cash : int;
  initial_date : string;
  final_date : string;
  final_portfolio : Portfolio.t;
  final_value : int;
  total_return : float;
  history : snapshot list;
}
(** A completed simulation. Monetary amounts are integer cents. [total_return]
    is a percentage, so [6.0] means a six-percent gain. [history] contains one
    snapshot per input date in file order. Final cash and holdings are available
    through Portfolio's accessors on [final_portfolio]. Fields are read-only. *)

val run :
  name:string ->
  init:(Strategy.init_context -> ('state, string) result) ->
  step:('state -> Strategy.observation -> Order.t list * 'state) ->
  ?options:(string * string) list ->
  Market.t ->
  initial_cash:int ->
  (t, string) result
(** [run ~name ~init ~step market ~initial_cash] runs one strategy. Supply
    [name], [init], and [step] from the same module sealed with [Strategy.S].
    Ordinary function arguments allow the same engine to carry any abstract
    strategy state without functors, first-class modules, or strategy-specific
    branches.

    Initialization receives security names, initial cash, and [options] (default
    [[]]), but no prices. Each subsequent [step] receives only the current row
    and the portfolio before its orders. Orders execute left to right;
    rejections preserve the portfolio and do not prevent later orders. Valuation
    uses that same row after all orders, and the resulting portfolio and
    strategy state carry forward to the next date. No other price rows are
    passed to strategies.

    Returns [Error message] for nonpositive initial cash, rejected strategy
    initialization, or a valuation error. Final summary values are returned as
    structured data for the reporting layer to format. *)
