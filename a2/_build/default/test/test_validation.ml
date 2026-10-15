open OUnit2
module Backtest = A2.Backtest
module Market = A2.Market
module Order = A2.Order
module Portfolio = A2.Portfolio
module Strategy = A2.Strategy

let get_ok = function
  | Ok value -> value
  | Error message -> assert_failure message

let print_list print values =
  "[" ^ String.concat "; " (List.map print values) ^ "]"

let print_holdings =
  print_list (fun (security, quantity) ->
      Printf.sprintf "%s=%d" security quantity)

let print_orders =
  print_list (function
    | Order.Buy (security, quantity) ->
        Printf.sprintf "buy %d %s" quantity security
    | Order.Sell (security, quantity) ->
        Printf.sprintf "sell %d %s" quantity security)

(* Expected orders, cash, holdings, and values below are independently
   worked-out literals. The helper only calls public interfaces and compares
   results; it does not calculate an expected trade or portfolio value. *)
let check_run name init step ?(options = []) filename initial_cash expected _ =
  let market = get_ok (Market.load filename) in
  let result =
    get_ok (Backtest.run ~name ~init ~step ~options market ~initial_cash)
  in
  assert_equal
    ~msg:(name ^ ": one snapshot per expected date")
    ~printer:string_of_int (List.length expected)
    (List.length result.history);
  List.iter2
    (fun (date, orders, cash, holdings, value) (actual : Backtest.snapshot) ->
      let message field = Printf.sprintf "%s on %s: %s" name date field in
      assert_equal ~msg:(message "date") ~printer:Fun.id date actual.date;
      assert_equal ~msg:(message "orders") ~printer:print_orders orders
        actual.orders;
      assert_equal
        ~msg:(message "one successful outcome per order")
        (List.map (fun _ -> Order.Executed) orders)
        actual.outcomes;
      assert_equal ~msg:(message "cash in cents") ~printer:string_of_int cash
        (Portfolio.cash actual.portfolio);
      assert_equal
        ~msg:(message "whole-share holdings")
        ~printer:print_holdings
        (List.sort compare holdings)
        (List.sort compare (Portfolio.holdings actual.portfolio));
      assert_equal ~msg:(message "value in cents") ~printer:string_of_int value
        actual.value)
    expected result.history;
  let first_date, _, _, _, _ = List.hd expected in
  let last_date, _, final_cash, final_holdings, final_value =
    List.hd (List.rev expected)
  in
  assert_equal ~msg:"summary strategy" name result.strategy;
  assert_equal ~msg:"summary initial cash" initial_cash result.initial_cash;
  assert_equal ~msg:"summary first date" first_date result.initial_date;
  assert_equal ~msg:"summary last date" last_date result.final_date;
  assert_equal ~msg:"summary final cash" final_cash
    (Portfolio.cash result.final_portfolio);
  assert_equal ~msg:"summary final holdings"
    (List.sort compare final_holdings)
    (List.sort compare (Portfolio.holdings result.final_portfolio));
  assert_equal ~msg:"summary final value" final_value result.final_value

let cash_handout =
  [
    ("2024-01-02", [], 10000, [], 10000);
    ("2024-01-03", [], 10000, [], 10000);
    ("2024-01-04", [], 10000, [], 10000);
  ]

let buy_handout =
  [
    ("2024-01-02", [ Order.Buy ("ALFA", 10) ], 5, [ ("ALFA", 10) ], 10005);
    ("2024-01-03", [], 5, [ ("ALFA", 10) ], 12005);
    ("2024-01-04", [], 5, [ ("ALFA", 10) ], 11005);
  ]

let buy_tiny =
  [
    ("2024-02-26", [ Order.Buy ("ZED", 3) ], 100, [ ("ZED", 3) ], 1000);
    ("2024-02-27", [], 100, [ ("ZED", 3) ], 1300);
    ("2024-02-28", [], 100, [ ("ZED", 3) ], 1150);
    ("2024-02-29", [], 100, [ ("ZED", 3) ], 1225);
    ("2024-03-01", [], 100, [ ("ZED", 3) ], 1300);
    ("2024-03-04", [], 100, [ ("ZED", 3) ], 1450);
    ("2024-03-05", [], 100, [ ("ZED", 3) ], 1600);
    ("2024-03-06", [], 100, [ ("ZED", 3) ], 1600);
  ]

let buy_budget =
  [
    ("2024-04-01", [], 100, [], 100);
    ("2024-04-02", [], 100, [], 100);
    ("2024-04-03", [], 100, [], 100);
    ("2024-04-04", [], 100, [], 100);
    ("2024-04-05", [], 100, [], 100);
    ("2024-04-08", [], 100, [], 100);
    ("2024-04-09", [], 100, [], 100);
    ("2024-04-10", [], 100, [], 100);
    ("2024-04-11", [], 100, [], 100);
  ]

let momentum_handout =
  [
    ("2024-01-02", [], 10000, [], 10000);
    ("2024-01-03", [ Order.Buy ("ALFA", 8) ], 400, [ ("ALFA", 8) ], 10000);
    ( "2024-01-04",
      [ Order.Sell ("ALFA", 8); Order.Buy ("BETA", 4) ],
      800,
      [ ("BETA", 4) ],
      9200 );
  ]

let momentum_tiny =
  [
    ("2024-02-26", [], 1000, [], 1000);
    ("2024-02-27", [ Order.Buy ("ZED", 2) ], 200, [ ("ZED", 2) ], 1000);
    ("2024-02-28", [], 200, [ ("ZED", 2) ], 900);
    ( "2024-02-29",
      [ Order.Sell ("ZED", 2); Order.Buy ("Q7", 1) ],
      50,
      [ ("Q7", 1) ],
      950 );
    ( "2024-03-01",
      [ Order.Sell ("Q7", 1); Order.Buy ("ALFA", 1) ],
      350,
      [ ("ALFA", 1) ],
      1050 );
    ( "2024-03-04",
      [ Order.Sell ("ALFA", 1); Order.Buy ("ZED", 2) ],
      200,
      [ ("ZED", 2) ],
      1100 );
    ("2024-03-05", [], 200, [ ("ZED", 2) ], 1200);
    ("2024-03-06", [], 200, [ ("ZED", 2) ], 1200);
  ]

let momentum_budget =
  [
    ("2024-04-01", [], 100, [], 100);
    ("2024-04-02", [ Order.Buy ("WREN", 2) ], 0, [ ("WREN", 2) ], 100);
    ("2024-04-03", [ Order.Sell ("WREN", 2) ], 100, [], 100);
    ("2024-04-04", [], 100, [], 100);
    ("2024-04-05", [], 100, [], 100);
    ("2024-04-08", [], 100, [], 100);
    ("2024-04-09", [ Order.Buy ("WREN", 1) ], 40, [ ("WREN", 1) ], 100);
    ("2024-04-10", [], 40, [ ("WREN", 1) ], 100);
    ("2024-04-11", [], 40, [ ("WREN", 1) ], 70);
  ]

let tests =
  "R7 validation"
  >::: [
         "Cash"
         >::: [
                "handout dated states"
                >:: check_run Strategy.Cash.name Strategy.Cash.init
                      Strategy.Cash.step "../data/handout.csv" 10000
                      cash_handout;
              ];
         "Buy-and-hold"
         >::: [
                "handout dated states"
                >:: check_run Strategy.Buy_and_hold.name
                      Strategy.Buy_and_hold.init Strategy.Buy_and_hold.step
                      ~options:[ ("hold", "ALFA") ]
                      "../data/handout.csv" 10005 buy_handout;
                "tiny dated states"
                >:: check_run Strategy.Buy_and_hold.name
                      Strategy.Buy_and_hold.init Strategy.Buy_and_hold.step
                      ~options:[ ("hold", "ZED") ]
                      "../data/strategy-tiny.csv" 1000 buy_tiny;
                "unaffordable first date is never retried"
                >:: check_run Strategy.Buy_and_hold.name
                      Strategy.Buy_and_hold.init Strategy.Buy_and_hold.step
                      ~options:[ ("hold", "LYNX") ]
                      "../data/strategy-budget.csv" 100 buy_budget;
              ];
         "Momentum"
         >::: [
                "handout dated states"
                >:: check_run Strategy.Momentum.name Strategy.Momentum.init
                      Strategy.Momentum.step "../data/handout.csv" 10000
                      momentum_handout;
                "tiny dated states"
                >:: check_run Strategy.Momentum.name Strategy.Momentum.init
                      Strategy.Momentum.step "../data/strategy-tiny.csv" 1000
                      momentum_tiny;
                "unaffordable switch, retained target, and loss"
                >:: check_run Strategy.Momentum.name Strategy.Momentum.init
                      Strategy.Momentum.step "../data/strategy-budget.csv" 100
                      momentum_budget;
              ];
       ]

let () = run_test_tt_main tests
