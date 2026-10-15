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

module Cash : S = struct
  type state = unit

  let name = "cash"

  (** [init context] returns a cash strategy's initial state. The general
      [context] is unused, and no strategy-specific options are required. *)
  let init _context = Ok ()

  (** [step state observation] proposes no orders and preserves [state]. The
      current-day [observation] does not affect the cash strategy. *)
  let step state _observation = ([], state)
end

module Buy_and_hold : S = struct
  type state =
    | Waiting of string
    | Done

  let name = "buy-and-hold"

  (** [init context] prepares a single first-date purchase of the security named
      by the ["hold"] option. Returns an error if that option is absent or does
      not exactly match a security in [context.securities]. *)
  let init context =
    match List.assoc_opt "hold" context.options with
    | None -> Error "Buy-and-hold requires --hold SYMBOL"
    | Some security when not (List.mem security context.securities) ->
        Error (Printf.sprintf "Unknown --hold security %S" security)
    | Some security -> Ok (Waiting security)

  (** [step state observation] proposes the largest affordable whole-share
      purchase on the first observation and no orders afterward, including when
      no first-date share was affordable. Returns the next immutable state.
      Requires a current observation satisfying the [observation] contract. *)
  let step state observation =
    match state with
    | Done -> ([], Done)
    | Waiting security ->
        let quantity =
          observation.cash / List.assoc security observation.prices
        in
        let orders =
          if quantity = 0 then [] else [ Order.Buy (security, quantity) ]
        in
        (orders, Done)
end

module Momentum : S = struct
  type state = {
    securities : string list;
    previous : (string * int) list option;
    target : string option;
  }

  let name = "momentum"

  (** [init context] returns momentum state with the header-order securities
      from [context], no previous prices, and no target. No strategy-specific
      options are required. *)
  let init (context : init_context) =
    Ok { securities = context.securities; previous = None; target = None }

  (** [select_target securities previous prices] selects the largest strictly
      positive cent increase from [previous] to [prices], or [None] if there is
      none. Ties favor the first name in [securities]. Requires unique names in
      header order and a price for each name in both price lists. *)
  let select_target securities previous prices =
    let target, _ =
      List.fold_left
        (fun (target, largest_gain) security ->
          let gain =
            List.assoc security prices - List.assoc security previous
          in
          if gain > largest_gain then (Some security, gain)
          else (target, largest_gain))
        (None, 0) securities
    in
    target

  (** [switch_orders observation security] proposes sales of all positive
      holdings followed by the largest whole-share purchase affordable with
      current cash and sale proceeds. The purchase is omitted if unaffordable.
      Requires a valid current [observation] that includes [security]'s price.
  *)
  let switch_orders observation security =
    let sales =
      List.filter_map
        (fun (held, quantity) ->
          if quantity > 0 then Some (Order.Sell (held, quantity)) else None)
        observation.holdings
    in
    let buying_power =
      List.fold_left
        (fun cash (held, quantity) ->
          cash + (quantity * List.assoc held observation.prices))
        observation.cash observation.holdings
    in
    let quantity = buying_power / List.assoc security observation.prices in
    let purchases =
      if quantity = 0 then [] else [ Order.Buy (security, quantity) ]
    in
    sales @ purchases

  (** [step state observation] proposes default one-day momentum orders and
      returns state remembering the current prices and retained/new target. The
      first date only records prices. A changed positive-gain target causes a
      full switch; no gain or an unchanged target causes no orders. Even an
      unaffordable new target is remembered. Requires a current observation
      satisfying the [observation] contract for the initialized securities. *)
  let step state observation =
    let orders, target =
      match state.previous with
      | None -> ([], None)
      | Some previous -> (
          match select_target state.securities previous observation.prices with
          | None -> ([], state.target)
          | Some security as target ->
              if target = state.target then ([], target)
              else (switch_orders observation security, target))
    in
    (orders, { state with previous = Some observation.prices; target })
end
