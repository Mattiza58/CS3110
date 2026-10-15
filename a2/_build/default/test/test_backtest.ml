open OUnit2
module Backtest = A2.Backtest
module Market = A2.Market
module Order = A2.Order
module Portfolio = A2.Portfolio
module Strategy = A2.Strategy

(** [get_ok result] extracts an [Ok] value or fails the OUnit assertion with the
    message carried by [Error]. *)
let get_ok = function
  | Ok value -> value
  | Error message -> assert_failure message

(** [run name init step ~options ~cash filename] loads a valid market and runs
    the supplied sealed strategy operations, failing the assertion on an error.
    Defaults are no options and 10000 initial cents. *)
let run name init step ?(options = []) ?(cash = 10000) filename =
  let market = get_ok (Market.load filename) in
  get_ok (Backtest.run ~name ~init ~step ~options market ~initial_cash:cash)

(** [snapshots result] returns chronological
    date/cash/holdings/value/orders/outcome tuples for comparing completed
    simulations. Holdings are sorted by name for stable comparison. *)
let snapshots (result : Backtest.t) =
  List.map
    (fun (snapshot : Backtest.snapshot) ->
      ( snapshot.date,
        Portfolio.cash snapshot.portfolio,
        List.sort compare (Portfolio.holdings snapshot.portfolio),
        snapshot.value,
        snapshot.orders,
        snapshot.outcomes ))
    result.history

(** [assert_return expected actual] checks percentage returns with an absolute
    tolerance below one billionth of a percentage point. *)
let assert_return expected actual =
  assert_equal ~printer:string_of_float
    ~cmp:(fun a b -> abs_float (a -. b) < 1e-9)
    expected actual

(** [with_market contents test] loads valid CSV [contents] from a temporary file
    and passes the market to [test]. The temporary file is removed even if
    parsing or the callback fails. *)
let with_market contents test =
  let filename = Filename.temp_file "a2-backtest-" ".csv" in
  Fun.protect
    ~finally:(fun () -> Sys.remove filename)
    (fun () ->
      let channel = open_out_bin filename in
      Fun.protect
        ~finally:(fun () -> close_out_noerr channel)
        (fun () -> output_string channel contents);
      test (get_ok (Market.load filename)))

(* A test-only strategy replays the accounting example and verifies the exact
   pre-order observation and carried private state at each date. *)
module Reference : Strategy.S = struct
  type state = int

  let name = "accounting-reference"

  (** [init context] asserts the expected security names, initial cents, and
      marker option, then returns the first Accounting Reference step index. *)
  let init (context : Strategy.init_context) =
    assert_equal [ "ALFA"; "BETA" ] context.securities;
    assert_equal 10000 context.initial_cash;
    assert_equal [ ("marker", "checked") ] context.options;
    Ok 0

  (** [step state observation] asserts the exact pre-order observation for the
      current Accounting Reference index and returns its prescribed orders and
      next index. Fails if called beyond the three expected dates. *)
  let step state (observation : Strategy.observation) =
    let date, prices, cash, holdings, orders =
      match state with
      | 0 ->
          ( "2024-01-02",
            [ ("ALFA", 1000); ("BETA", 2500) ],
            10000,
            [],
            [ Order.Buy ("ALFA", 3) ] )
      | 1 ->
          ( "2024-01-03",
            [ ("ALFA", 1200); ("BETA", 2000) ],
            7000,
            [ ("ALFA", 3) ],
            [ Order.Sell ("ALFA", 1); Order.Buy ("BETA", 2) ] )
      | 2 ->
          ( "2024-01-04",
            [ ("ALFA", 1100); ("BETA", 2100) ],
            4200,
            [ ("ALFA", 2); ("BETA", 2) ],
            [ Order.Buy ("ALFA", 4); Order.Sell ("BETA", 1) ] )
      | _ -> assert_failure "Unexpected extra strategy step"
    in
    assert_equal date observation.date;
    assert_equal prices observation.prices;
    assert_equal cash observation.cash;
    assert_equal holdings (List.sort compare observation.holdings);
    (orders, state + 1)
end

(** Checks all Accounting Reference observations, orders, outcomes, dated
    states, final summary fields, and the six-percent return through the engine.
*)
let accounting_reference_test _ =
  let result =
    run Reference.name Reference.init Reference.step
      ~options:[ ("marker", "checked") ]
      "../data/handout.csv"
  in
  assert_equal
    [
      ( "2024-01-02",
        7000,
        [ ("ALFA", 3) ],
        10000,
        [ Order.Buy ("ALFA", 3) ],
        [ Order.Executed ] );
      ( "2024-01-03",
        4200,
        [ ("ALFA", 2); ("BETA", 2) ],
        10600,
        [ Order.Sell ("ALFA", 1); Order.Buy ("BETA", 2) ],
        [ Order.Executed; Order.Executed ] );
      ( "2024-01-04",
        6300,
        [ ("ALFA", 2); ("BETA", 1) ],
        10600,
        [ Order.Buy ("ALFA", 4); Order.Sell ("BETA", 1) ],
        [ Order.Rejected Order.Insufficient_cash; Order.Executed ] );
    ]
    (snapshots result);
  assert_equal Reference.name result.strategy;
  assert_equal 10000 result.initial_cash;
  assert_equal "2024-01-02" result.initial_date;
  assert_equal "2024-01-04" result.final_date;
  assert_equal 6300 (Portfolio.cash result.final_portfolio);
  assert_equal
    [ ("ALFA", 2); ("BETA", 1) ]
    (List.sort compare (Portfolio.holdings result.final_portfolio));
  assert_equal 10600 result.final_value;
  assert_return 6.0 result.total_return

module Rejections : Strategy.S = struct
  type state = int

  let name = "test-rejections"

  (** [init context] returns the first scripted step index; the general
      initialization context is unused. *)
  let init _ = Ok 0

  (** [step state observation] proposes the rejection-test orders for the
      current index and returns the next index. The observation is unused; later
      indices produce no orders. *)
  let step state _ =
    let orders =
      match state with
      | 0 ->
          [
            Order.Buy ("ALFA", 0);
            Order.Sell ("ALFA", -1);
            Order.Buy ("MISSING", 1);
            Order.Sell ("MISSING", 1);
            Order.Sell ("ALFA", 1);
            Order.Buy ("ALFA", 11);
            Order.Buy ("ALFA", 2);
          ]
      | 1 ->
          [
            Order.Sell ("ALFA", 3); Order.Buy ("BETA", 5); Order.Sell ("ALFA", 1);
          ]
      | _ -> []
    in
    (orders, state + 1)
end

(** Checks all four rejection rules, continued later orders, dated portfolio
    carry-forward, and the predicted final return. *)
let rejections_test _ =
  let result =
    run Rejections.name Rejections.init Rejections.step "../data/handout.csv"
  in
  let first = List.hd result.history in
  assert_equal
    [
      Order.Rejected Order.Invalid_quantity;
      Order.Rejected Order.Invalid_quantity;
      Order.Rejected Order.Unknown_security;
      Order.Rejected Order.Unknown_security;
      Order.Rejected Order.Insufficient_shares;
      Order.Rejected Order.Insufficient_cash;
      Order.Executed;
    ]
    first.outcomes;
  assert_equal
    [
      ("2024-01-02", 8000, [ ("ALFA", 2) ], 10000);
      ("2024-01-03", 9200, [ ("ALFA", 1) ], 10400);
      ("2024-01-04", 9200, [ ("ALFA", 1) ], 10300);
    ]
    (List.map
       (fun (snapshot : Backtest.snapshot) ->
         ( snapshot.date,
           Portfolio.cash snapshot.portfolio,
           Portfolio.holdings snapshot.portfolio,
           snapshot.value ))
       result.history);
  let second = List.nth result.history 1 in
  assert_equal
    [
      Order.Rejected Order.Insufficient_shares;
      Order.Rejected Order.Insufficient_cash;
      Order.Executed;
    ]
    second.outcomes;
  assert_equal 10300 result.final_value;
  assert_return 3.0 result.total_return

(** [funding_step reversed state observation] returns a fixed funding-test
    script and incremented step index. Index zero buys ALFA; index one sells
    ALFA then buys BETA, reversing that pair when [reversed] is true. Later
    indices propose no orders. *)
let funding_step reversed state _ =
  let orders =
    match state with
    | 0 -> [ Order.Buy ("ALFA", 10) ]
    | 1 ->
        let orders = [ Order.Sell ("ALFA", 10); Order.Buy ("BETA", 6) ] in
        if reversed then List.rev orders else orders
    | _ -> []
  in
  (orders, state + 1)

module Sale_first : Strategy.S = struct
  type state = int

  let name = "sale-first"

  (** [init context] returns the first scripted step index; the general
      initialization context is unused. *)
  let init _ = Ok 0

  (** [step state observation] returns the funding-test script with a sale
      followed by its funded purchase, together with the next script index. *)
  let step = funding_step false
end

module Buy_first : Strategy.S = struct
  type state = int

  let name = "buy-first"

  (** [init context] returns the first scripted step index; the general
      initialization context is unused. *)
  let init _ = Ok 0

  (** [step state observation] returns the funding-test script with a purchase
      attempted before its funding sale, together with the next script index. *)
  let step = funding_step true
end

(** Checks that a sale funds a later purchase and that each recorded value uses
    that date's prices after execution. *)
let sale_funding_test _ =
  let result =
    run Sale_first.name Sale_first.init Sale_first.step "../data/handout.csv"
  in
  assert_equal
    [
      ("2024-01-02", 0, [ ("ALFA", 10) ], 10000);
      ("2024-01-03", 0, [ ("BETA", 6) ], 12000);
      ("2024-01-04", 0, [ ("BETA", 6) ], 12600);
    ]
    (List.map
       (fun (snapshot : Backtest.snapshot) ->
         ( snapshot.date,
           Portfolio.cash snapshot.portfolio,
           Portfolio.holdings snapshot.portfolio,
           snapshot.value ))
       result.history);
  assert_equal 12600 result.final_value;
  assert_return 26.0 result.total_return

(** Checks that purchasing before the funding sale is rejected while the sale
    still executes, producing the independently predicted final cash and return.
*)
let reversed_orders_test _ =
  let result =
    run Buy_first.name Buy_first.init Buy_first.step "../data/handout.csv"
  in
  let second = List.nth result.history 1 in
  assert_equal
    [ Order.Rejected Order.Insufficient_cash; Order.Executed ]
    second.outcomes;
  assert_equal 12000 (Portfolio.cash result.final_portfolio);
  assert_equal [] (Portfolio.holdings result.final_portfolio);
  assert_equal 12000 result.final_value;
  assert_return 20.0 result.total_return

(** Checks first/final dates, one snapshot, exact leftover cash, final
    holdings/value, and zero return for a one-date market. *)
let single_date_test _ =
  with_market "date,A\n2024-01-02,10.00" (fun market ->
      let result =
        get_ok
          (Backtest.run ~name:Strategy.Buy_and_hold.name
             ~init:Strategy.Buy_and_hold.init ~step:Strategy.Buy_and_hold.step
             ~options:[ ("hold", "A") ]
             market ~initial_cash:10005)
      in
      assert_equal result.initial_date result.final_date;
      assert_equal "2024-01-02" result.initial_date;
      assert_equal 1 (List.length result.history);
      assert_equal 5 (Portfolio.cash result.final_portfolio);
      assert_equal [ ("A", 10) ] (Portfolio.holdings result.final_portfolio);
      assert_equal 10005 result.final_value;
      assert_return 0.0 result.total_return)

(** [fractional_return_test price expected_value expected_return] checks a
    two-date buy-and-hold run with the supplied final dollar-price text and
    independently predicted final cents and percentage return. Requires valid
    positive two-decimal [price]. *)
let fractional_return_test price expected_value expected_return _ =
  with_market
    ("date,A\n2024-01-02,3.00\n2024-01-03," ^ price ^ "\n")
    (fun market ->
      let result =
        get_ok
          (Backtest.run ~name:Strategy.Buy_and_hold.name
             ~init:Strategy.Buy_and_hold.init ~step:Strategy.Buy_and_hold.step
             ~options:[ ("hold", "A") ]
             market ~initial_cash:1000)
      in
      assert_equal 100 (Portfolio.cash result.final_portfolio);
      assert_equal [ ("A", 3) ] (Portfolio.holdings result.final_portfolio);
      assert_equal expected_value result.final_value;
      assert_return expected_return result.total_return)

module Never_initialized : Strategy.S = struct
  type state = unit

  let name = "never-initialized"

  (** [init context] always fails the assertion: the invalid-cash test requires
      the engine to reject input before calling this sentinel initializer. *)
  let init _ =
    assert_failure "Initial cash must be checked before strategy init"

  (** [step state observation] proposes no orders and preserves the sentinel
      state; the observation is unused. *)
  let step state _ = ([], state)
end

(** Checks rejection of nonpositive initial cash before the engine calls
    strategy initialization. *)
let initial_cash_error_test _ =
  let market = get_ok (Market.load "../data/handout.csv") in
  List.iter
    (fun initial_cash ->
      assert_equal (Error "Initial cash must be positive")
        (Backtest.run ~name:Never_initialized.name ~init:Never_initialized.init
           ~step:Never_initialized.step market ~initial_cash))
    [ 0; -1 ]

(** Checks propagation of missing/unknown hold-option errors with the selected
    strategy identified. *)
let initialization_error_test _ =
  let market = get_ok (Market.load "../data/handout.csv") in
  List.iter
    (fun options ->
      match
        Backtest.run ~name:Strategy.Buy_and_hold.name
          ~init:Strategy.Buy_and_hold.init ~step:Strategy.Buy_and_hold.step
          ~options market ~initial_cash:10000
      with
      | Error message ->
          assert_bool "Error identifies the strategy"
            (String.starts_with ~prefix:"buy-and-hold: " message)
      | Ok _ -> assert_failure "Expected strategy initialization error")
    [ []; [ ("hold", "MISSING") ] ]

(** Checks that changing only the final price row changes later results while
    preserving every earlier order, outcome, and portfolio snapshot. *)
let future_prices_test _ =
  let original =
    run Strategy.Momentum.name Strategy.Momentum.init Strategy.Momentum.step
      "../data/handout.csv"
  in
  with_market
    "date,ALFA,BETA\n\
     2024-01-02,10.00,25.00\n\
     2024-01-03,12.00,20.00\n\
     2024-01-04,0.01,999.99\n" (fun market ->
      let changed =
        get_ok
          (Backtest.run ~name:Strategy.Momentum.name
             ~init:Strategy.Momentum.init ~step:Strategy.Momentum.step market
             ~initial_cash:10000)
      in
      let prefix result =
        List.filter
          (fun (date, _, _, _, _, _) -> date < "2024-01-04")
          (snapshots result)
      in
      assert_equal (prefix original) (prefix changed);
      assert_bool "Later prices affect only later results"
        (original.final_value <> changed.final_value))

(** Checks an unchanged cash portfolio, empty orders/outcomes, date range, and
    return across the entire large historical market. *)
let historical_cash_test _ =
  let result =
    run Strategy.Cash.name Strategy.Cash.init Strategy.Cash.step ~cash:1000000
      "../data/large-dotcom-ca2000.csv"
  in
  assert_equal 748 (List.length result.history);
  assert_equal "1999-01-04" result.initial_date;
  assert_equal "2001-12-31" result.final_date;
  List.iter
    (fun (snapshot : Backtest.snapshot) ->
      assert_equal 1000000 (Portfolio.cash snapshot.portfolio);
      assert_equal [] (Portfolio.holdings snapshot.portfolio);
      assert_equal 1000000 snapshot.value;
      assert_equal [] snapshot.orders;
      assert_equal [] snapshot.outcomes)
    result.history;
  assert_return 0.0 result.total_return

(** Checks that repeated Momentum runs initialize fresh state and reproduce all
    dated results and the predicted negative return. *)
let fresh_run_test _ =
  let first =
    run Strategy.Momentum.name Strategy.Momentum.init Strategy.Momentum.step
      "../data/handout.csv"
  in
  let second =
    run Strategy.Momentum.name Strategy.Momentum.init Strategy.Momentum.step
      "../data/handout.csv"
  in
  assert_equal (snapshots first) (snapshots second);
  assert_equal 800 (Portfolio.cash second.final_portfolio);
  assert_equal [ ("BETA", 4) ] (Portfolio.holdings second.final_portfolio);
  assert_equal 9200 second.final_value;
  assert_return (-8.0) second.total_return

let tests =
  "Backtest"
  >::: [
         "accounting reference and current observations"
         >:: accounting_reference_test;
         "all rejection rules continue processing" >:: rejections_test;
         "sale funds purchase and current-date valuation" >:: sale_funding_test;
         "reversing orders changes outcome" >:: reversed_orders_test;
         "single date" >:: single_date_test;
         "fractional positive return" >:: fractional_return_test "3.01" 1003 0.3;
         "fractional negative return"
         >:: fractional_return_test "2.99" 997 (-0.3);
         "invalid initial cash before strategy init" >:: initial_cash_error_test;
         "strategy initialization errors" >:: initialization_error_test;
         "future prices leave earlier results unchanged" >:: future_prices_test;
         "large historical cash run" >:: historical_cash_test;
         "fresh state on repeated runs" >:: fresh_run_test;
       ]

let () = run_test_tt_main tests
