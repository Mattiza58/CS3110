(** Trading rules with private, immutable state. Strategies propose orders;
    Portfolio executes them. This module performs no file or terminal I/O. *)

type init_context = {
  securities : string list;
  initial_cash : int;
  options : (string * string) list;
}
(** Facts available before simulation. [securities] contains unique market names
    in header order, [initial_cash] is positive integer cents, and [options]
    uses option names without leading dashes (for example, [("hold", "ALFA")]).
    No price rows are supplied during initialization. *)

type observation = {
  date : string;
  prices : (string * int) list;
  cash : int;
  holdings : (string * int) list;
}
(** Only the current date's prices and portfolio view before orders execute. The
    engine must supply dates sequentially, with every initialized security's
    positive integer-cent price exactly once. Cash and whole-share holdings are
    nonnegative; holding names are unique and belong to the market. *)

module type S = sig
  type state
  (** Private strategy state, carried between dates without inspection. *)

  val name : string
  (** The command-line strategy name. *)

  val init : init_context -> (state, string) result
  (** Validate strategy-specific options and construct the initial state. *)

  val step : state -> observation -> Order.t list * state
  (** Propose orders in execution order and return the next state. The input
      state is not mutated. Earlier information must be retained privately; no
      other price rows or operations for retrieving them are available. *)
end

module Cash : S
(** Always proposes no orders. No strategy-specific options are required. *)

module Buy_and_hold : S
(** Requires ["hold"] to name an initialized security, matched exactly. On its
    first observation, proposes the largest affordable whole-share purchase.
    Proposes no later orders, including if the first purchase was unaffordable.
*)

module Momentum : S
(** The default one-day momentum rule. The first observation only records
    prices. Later observations select the largest strictly positive absolute
    cent increase, breaking ties by header order. No positive gain retains the
    previous target without orders. A new target triggers sales of all holdings
    followed by the largest affordable purchase using cash plus sale proceeds.
    An unchanged target produces no orders. An unaffordable target is still
    remembered, and current prices are remembered on every step. No
    strategy-specific options are required. *)
