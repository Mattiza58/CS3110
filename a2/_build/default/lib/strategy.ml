type init_context = {
  securities : string list;
  initial_cash : int;
  options : (string * string) list;
}

type observation = {
  date : string;
  prices : (string * int) list;
  cash : int;
  holdings : (string * int) list;
}

module type S = sig
  type state

  val name : string
  val init : init_context -> (state, string) result
  val step : state -> observation -> Order.t list * state
end

module Cash : S = struct
  type state = unit

  let name = "cash"
  let init _ = Ok ()
  let step state _ = ([], state)
end

module Buy_and_hold : S = struct
  type state =
    | Waiting of string
    | Done

  let name = "buy-and-hold"

  let init context =
    match List.assoc_opt "hold" context.options with
    | None -> Error "Buy-and-hold requires --hold SYMBOL"
    | Some security when not (List.mem security context.securities) ->
        Error (Printf.sprintf "Unknown --hold security %S" security)
    | Some security -> Ok (Waiting security)

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

  let init (context : init_context) =
    Ok { securities = context.securities; previous = None; target = None }

  (* Strict improvement preserves the first security in header order on ties. *)
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
