(* Invariant: cash is nonnegative. Holdings have unique security names and
   strictly positive whole-share quantities; zero holdings are omitted. *)
type t = {
  cash : int;
  holdings : (string * int) list;
}

let create initial_cash =
  if initial_cash <= 0 then Error "Initial cash must be positive"
  else Ok { cash = initial_cash; holdings = [] }

let cash portfolio = portfolio.cash
let holdings portfolio = portfolio.holdings

let shares portfolio security =
  match List.assoc_opt security portfolio.holdings with
  | Some quantity -> quantity
  | None -> 0

let rec set_holding security quantity = function
  | [] -> if quantity = 0 then [] else [ (security, quantity) ]
  | (name, held) :: rest ->
      if name = security then
        if quantity = 0 then rest else (name, quantity) :: rest
      else (name, held) :: set_holding security quantity rest

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

let apply_orders portfolio prices orders =
  let portfolio, outcomes =
    List.fold_left
      (fun (portfolio, outcomes) order ->
        let portfolio, outcome = apply_order portfolio prices order in
        (portfolio, outcome :: outcomes))
      (portfolio, []) orders
  in
  (portfolio, List.rev outcomes)

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
