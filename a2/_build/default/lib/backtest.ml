type snapshot = {
  date : string;
  portfolio : Portfolio.t;
  value : int;
  orders : Order.t list;
  outcomes : Order.outcome list;
}

type t = {
  strategy : string;
  initial_cash : int;
  initial_date : string;
  final_date : string;
  final_portfolio : Portfolio.t;
  final_value : int;
  total_return : float;
  history : snapshot list;
}

(** [observe row portfolio] is the current day's strategy observation: [row]'s
    date/prices and the portfolio before that day's orders. Requires a valid
    market row with prices for every held security. *)
let observe (row : Market.row) portfolio : Strategy.observation =
  {
    date = row.date;
    prices = row.prices;
    cash = Portfolio.cash portfolio;
    holdings = Portfolio.holdings portfolio;
  }

(** [advance step state portfolio history rows] simulates [rows] in order and
    returns their post-order snapshots prepended to [history] in reverse date
    order, or a dated valuation error. [state] and [portfolio] describe the
    point before the first pending row. Requires [step] from the initialized
    strategy, valid ordered market rows, and [history] in reverse date order. *)
let rec advance step state portfolio history = function
  | [] -> Ok history
  | (row : Market.row) :: rest -> (
      let orders, state = step state (observe row portfolio) in
      let portfolio, outcomes =
        Portfolio.apply_orders portfolio row.prices orders
      in
      match Portfolio.value portfolio row.prices with
      | Error message ->
          Error (Printf.sprintf "Cannot value %s: %s" row.date message)
      | Ok value ->
          let snapshot =
            { date = row.date; portfolio; value; orders; outcomes }
          in
          advance step state portfolio (snapshot :: history) rest)

(** [summarize name initial_cash initial_date history] is the completed result
    for a run named [name], or an error if there are no snapshots. Requires
    positive initial cents and snapshots in reverse date order for a simulation
    beginning on [initial_date]. The returned history is chronological and the
    percentage return compares final value to [initial_cash]. *)
let summarize name initial_cash initial_date = function
  | [] -> Error "Cannot backtest a market without price rows"
  | final :: _ as history ->
      Ok
        {
          strategy = name;
          initial_cash;
          initial_date;
          final_date = final.date;
          final_portfolio = final.portfolio;
          final_value = final.value;
          total_return =
            float_of_int (final.value - initial_cash)
            /. float_of_int initial_cash *. 100.;
          history = List.rev history;
        }

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
let run ~name ~init ~step ?(options = []) market ~initial_cash =
  match Portfolio.create initial_cash with
  | Error message -> Error message
  | Ok initial_portfolio -> (
      let context : Strategy.init_context =
        { securities = Market.securities market; initial_cash; options }
      in
      match init context with
      | Error message -> Error (Printf.sprintf "%s: %s" name message)
      | Ok initial_state -> (
          match Market.rows market with
          | [] -> Error "Cannot backtest a market without price rows"
          | first :: _ as rows -> (
              match advance step initial_state initial_portfolio [] rows with
              | Error message -> Error message
              | Ok history -> summarize name initial_cash first.date history)))
