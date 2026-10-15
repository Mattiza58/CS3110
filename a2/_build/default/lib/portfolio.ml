(* Invariant: cash is nonnegative. Holdings have unique security names and
   strictly positive whole-share quantities; zero holdings are omitted. *)
type t = {
  cash : int;
  holdings : (string * int) list;
}

(** [create initial_cash] starts a portfolio with [initial_cash] cents and no
    shares. Returns [Error message] when [initial_cash] is not strictly
    positive. *)
let create initial_cash =
  if initial_cash <= 0 then Error "Initial cash must be positive"
  else Ok { cash = initial_cash; holdings = [] }

(** [cash portfolio] is the available cash in cents. *)
let cash portfolio = portfolio.cash

(** [holdings portfolio] contains each held security exactly once with its
    positive share quantity. Zero holdings are omitted. Order is unspecified. *)
let holdings portfolio = portfolio.holdings

(** [shares portfolio security] is the held share count, or zero if absent. *)
let shares portfolio security =
  match List.assoc_opt security portfolio.holdings with
  | Some quantity -> quantity
  | None -> 0

(** [set_holding security quantity holdings] replaces [security]'s share count,
    adds it if absent, or removes it when [quantity] is zero. Requires a
    nonnegative [quantity] and unique, strictly positive entries in [holdings].
*)
let rec set_holding security quantity = function
  | [] -> if quantity = 0 then [] else [ (security, quantity) ]
  | (name, held) :: rest ->
      if name = security then
        if quantity = 0 then rest else (name, quantity) :: rest
      else (name, held) :: set_holding security quantity rest

(** [apply_order portfolio prices order] executes an order at the supplied
    current prices or returns the unchanged portfolio with a rejection reason.
    Nonpositive quantities, securities absent from [prices], insufficient cash,
    and insufficient shares cause rejection. [prices] must be a valid market
    row's security/price associations, with unique names and positive cent
    prices. The input portfolio is never mutated. *)
let apply_order portfolio prices order =
  let security, quantity =
    match order with
    | Order.Buy (security, quantity) | Order.Sell (security, quantity) ->
        (security, quantity)
  in
  let reject reason = (portfolio, Order.Rejected reason) in
  if quantity <= 0 then reject Order.Invalid_quantity
  else
    match List.assoc_opt security prices with
    | None -> reject Order.Unknown_security
    | Some price -> (
        let held = shares portfolio security in
        let amount = quantity * price in
        let execute cash quantity =
          ( { cash; holdings = set_holding security quantity portfolio.holdings },
            Order.Executed )
        in
        match order with
        | Order.Buy _ ->
            if amount > portfolio.cash then reject Order.Insufficient_cash
            else execute (portfolio.cash - amount) (held + quantity)
        | Order.Sell _ ->
            if quantity > held then reject Order.Insufficient_shares
            else execute (portfolio.cash + amount) (held - quantity))

(** [apply_orders portfolio prices orders] processes orders from left to right,
    using each resulting portfolio for the next order. Sale proceeds are
    available to later purchases. Rejection does not stop processing. Outcomes
    appear in the same order as the proposed orders. [prices] has the same
    requirements as for [apply_order]. *)
let apply_orders portfolio prices orders =
  let portfolio, outcomes =
    List.fold_left
      (fun (portfolio, outcomes) order ->
        let portfolio, outcome = apply_order portfolio prices order in
        (portfolio, outcome :: outcomes))
      (portfolio, []) orders
  in
  (portfolio, List.rev outcomes)

(** [value portfolio prices] is cash plus holdings valued at the supplied
    current cent prices. Returns [Error message] if a held security has no
    price. Prices must have unique names and strictly positive values. *)
let value portfolio prices =
  let rec sum total = function
    | [] -> Ok total
    | (security, quantity) :: rest -> (
        match List.assoc_opt security prices with
        | Some price -> sum (total + (quantity * price)) rest
        | None ->
            Error (Printf.sprintf "Missing price for held security %S" security)
        )
  in
  sum portfolio.cash portfolio.holdings
