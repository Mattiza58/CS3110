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
          | first :: _ as rows ->
              let rec advance state portfolio history = function
                | [] -> (
                    match history with
                    | [] -> Error "Cannot backtest a market without price rows"
                    | final :: _ ->
                        Ok
                          {
                            strategy = name;
                            initial_cash;
                            initial_date = first.date;
                            final_date = final.date;
                            final_portfolio = final.portfolio;
                            final_value = final.value;
                            total_return =
                              float_of_int (final.value - initial_cash)
                              /. float_of_int initial_cash *. 100.;
                            history = List.rev history;
                          })
                | (row : Market.row) :: rest -> (
                    let observation : Strategy.observation =
                      {
                        date = row.date;
                        prices = row.prices;
                        cash = Portfolio.cash portfolio;
                        holdings = Portfolio.holdings portfolio;
                      }
                    in
                    let orders, state = step state observation in
                    let portfolio, outcomes =
                      Portfolio.apply_orders portfolio row.prices orders
                    in
                    match Portfolio.value portfolio row.prices with
                    | Error message ->
                        Error
                          (Printf.sprintf "Cannot value %s: %s" row.date message)
                    | Ok value ->
                        let snapshot =
                          {
                            date = row.date;
                            portfolio;
                            value;
                            orders;
                            outcomes;
                          }
                        in
                        advance state portfolio (snapshot :: history) rest)
              in
              advance initial_state initial_portfolio [] rows))
