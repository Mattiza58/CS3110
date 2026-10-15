open OUnit2
module Market = A2.Market
module Order = A2.Order
module Portfolio = A2.Portfolio

let get_ok = function
  | Ok value -> value
  | Error message -> assert_failure message

let create cash = get_ok (Portfolio.create cash)

let assert_state portfolio prices cash holdings value =
  assert_equal ~msg:"cash" ~printer:string_of_int cash
    (Portfolio.cash portfolio);
  assert_equal ~msg:"holdings"
    (List.sort compare holdings)
    (List.sort compare (Portfolio.holdings portfolio));
  List.iter
    (fun (security, quantity) ->
      assert_equal ~msg:("shares of " ^ security) ~printer:string_of_int
        quantity
        (Portfolio.shares portfolio security))
    holdings;
  assert_equal ~msg:"portfolio value" ~printer:string_of_int value
    (get_ok (Portfolio.value portfolio prices))

let initial_test _ =
  let portfolio = create 10003 in
  assert_state portfolio [] 10003 [] 10003;
  assert_equal 0 (Portfolio.shares portfolio "UNHELD");
  assert_state (create 1) [] 1 [] 1;
  List.iter
    (fun cash ->
      match Portfolio.create cash with
      | Error _ -> ()
      | Ok _ ->
          assert_failure "Expected nonpositive initial cash to be rejected")
    [ 0; -1 ]

let buy_test _ =
  let prices = [ ("XYZ", 1705) ] in
  let initial = create 10000 in
  let bought, outcome =
    Portfolio.apply_order initial prices (Order.Buy ("XYZ", 3))
  in
  assert_equal Order.Executed outcome;
  assert_state bought prices 4885 [ ("XYZ", 3) ] 10000;
  let more, outcome =
    Portfolio.apply_order bought prices (Order.Buy ("XYZ", 2))
  in
  assert_equal Order.Executed outcome;
  assert_state more prices 1475 [ ("XYZ", 5) ] 10000;
  assert_state initial prices 10000 [] 10000;
  assert_state bought prices 4885 [ ("XYZ", 3) ] 10000

let sell_test _ =
  let bought, _ =
    Portfolio.apply_order (create 10000)
      [ ("XYZ", 1250) ]
      (Order.Buy ("XYZ", 4))
  in
  let prices = [ ("XYZ", 1500) ] in
  let sold, outcome =
    Portfolio.apply_order bought prices (Order.Sell ("XYZ", 2))
  in
  assert_equal Order.Executed outcome;
  assert_state sold prices 8000 [ ("XYZ", 2) ] 11000;
  let liquidated, outcome =
    Portfolio.apply_order sold prices (Order.Sell ("XYZ", 2))
  in
  assert_equal Order.Executed outcome;
  assert_state liquidated prices 11000 [] 11000;
  assert_equal 0 (Portfolio.shares liquidated "XYZ");
  assert_state bought prices 5000 [ ("XYZ", 4) ] 11000

let rejection_test order reason _ =
  let prices = [ ("XYZ", 1000) ] in
  let portfolio, _ =
    Portfolio.apply_order (create 10000) prices (Order.Buy ("XYZ", 2))
  in
  let rejected, outcome = Portfolio.apply_order portfolio prices order in
  assert_equal (Order.Rejected reason) outcome;
  assert_state rejected prices 8000 [ ("XYZ", 2) ] 10000;
  assert_state portfolio prices 8000 [ ("XYZ", 2) ] 10000

let funding_test reversed _ =
  let bought, _ =
    Portfolio.apply_order (create 1000)
      [ ("A", 1000); ("B", 400) ]
      (Order.Buy ("A", 1))
  in
  let prices = [ ("A", 1200); ("B", 400) ] in
  let orders = [ Order.Sell ("A", 1); Order.Buy ("B", 3) ] in
  let orders = if reversed then List.rev orders else orders in
  let final, outcomes = Portfolio.apply_orders bought prices orders in
  if reversed then (
    assert_equal
      [ Order.Rejected Order.Insufficient_cash; Order.Executed ]
      outcomes;
    assert_state final prices 1200 [] 1200)
  else (
    assert_equal [ Order.Executed; Order.Executed ] outcomes;
    assert_state final prices 0 [ ("B", 3) ] 1200);
  assert_state bought prices 0 [ ("A", 1) ] 1200

let continue_after_rejection_test _ =
  let prices = [ ("XYZ", 1000) ] in
  let final, outcomes =
    Portfolio.apply_orders (create 2500) prices
      [
        Order.Buy ("XYZ", 0);
        Order.Buy ("MISSING", 1);
        Order.Buy ("XYZ", 3);
        Order.Sell ("XYZ", 1);
        Order.Buy ("XYZ", 2);
        Order.Sell ("XYZ", 1);
        Order.Buy ("XYZ", 1);
      ]
  in
  assert_equal
    [
      Order.Rejected Order.Invalid_quantity;
      Order.Rejected Order.Unknown_security;
      Order.Rejected Order.Insufficient_cash;
      Order.Rejected Order.Insufficient_shares;
      Order.Executed;
      Order.Executed;
      Order.Executed;
    ]
    outcomes;
  assert_state final prices 500 [ ("XYZ", 2) ] 2500

let empty_orders_test _ =
  let initial = create 10000 in
  let final, outcomes = Portfolio.apply_orders initial [] [] in
  assert_equal [] outcomes;
  assert_state final [] 10000 [] 10000

let missing_valuation_price_test _ =
  let portfolio, _ =
    Portfolio.apply_order (create 10000)
      [ ("XYZ", 1000) ]
      (Order.Buy ("XYZ", 2))
  in
  assert_equal (Error "Missing price for held security \"XYZ\"")
    (Portfolio.value portfolio [ ("OTHER", 500) ]);
  assert_state portfolio [ ("XYZ", 1500) ] 8000 [ ("XYZ", 2) ] 11000

let accounting_reference_test _ =
  let market = get_ok (Market.load "../data/handout.csv") in
  let scenarios =
    [
      ( [ Order.Buy ("ALFA", 3) ],
        [ Order.Executed ],
        7000,
        [ ("ALFA", 3) ],
        10000 );
      ( [ Order.Sell ("ALFA", 1); Order.Buy ("BETA", 2) ],
        [ Order.Executed; Order.Executed ],
        4200,
        [ ("ALFA", 2); ("BETA", 2) ],
        10600 );
      ( [ Order.Buy ("ALFA", 4); Order.Sell ("BETA", 1) ],
        [ Order.Rejected Order.Insufficient_cash; Order.Executed ],
        6300,
        [ ("ALFA", 2); ("BETA", 1) ],
        10600 );
    ]
  in
  ignore
    (List.fold_left2
       (fun portfolio (row : Market.row)
            (orders, expected, cash, holdings, value) ->
         let next, outcomes =
           Portfolio.apply_orders portfolio row.prices orders
         in
         assert_equal ~msg:row.date expected outcomes;
         assert_state next row.prices cash holdings value;
         next)
       (create 10000) (Market.rows market) scenarios)

let independent_accounting_test _ =
  let first_prices = [ ("ZED", 333); ("Q7", 1250) ] in
  let first, outcomes =
    Portfolio.apply_orders (create 10003) first_prices [ Order.Buy ("ZED", 10) ]
  in
  assert_equal [ Order.Executed ] outcomes;
  assert_state first first_prices 6673 [ ("ZED", 10) ] 10003;
  let second_prices = [ ("ZED", 400); ("Q7", 1000) ] in
  let second, outcomes =
    Portfolio.apply_orders first second_prices
      [ Order.Sell ("ZED", 3); Order.Buy ("Q7", 7) ]
  in
  assert_equal [ Order.Executed; Order.Executed ] outcomes;
  assert_state second second_prices 873 [ ("ZED", 7); ("Q7", 7) ] 10673;
  let third_prices = [ ("ZED", 250); ("Q7", 1400) ] in
  let third, outcomes =
    Portfolio.apply_orders second third_prices
      [ Order.Buy ("ZED", 4); Order.Sell ("Q7", 2) ]
  in
  assert_equal
    [ Order.Rejected Order.Insufficient_cash; Order.Executed ]
    outcomes;
  assert_state third third_prices 3673 [ ("ZED", 7); ("Q7", 5) ] 12423

let tests =
  "Portfolio accounting"
  >::: [
         "initial state and cash validation" >:: initial_test;
         "buy and accumulate exact cents" >:: buy_test;
         "sell and remove zero holdings" >:: sell_test;
         "zero buy quantity"
         >:: rejection_test (Order.Buy ("XYZ", 0)) Order.Invalid_quantity;
         "negative buy quantity"
         >:: rejection_test (Order.Buy ("XYZ", -1)) Order.Invalid_quantity;
         "zero sell quantity"
         >:: rejection_test (Order.Sell ("XYZ", 0)) Order.Invalid_quantity;
         "negative sell quantity"
         >:: rejection_test (Order.Sell ("XYZ", -1)) Order.Invalid_quantity;
         "unknown buy security"
         >:: rejection_test (Order.Buy ("MISSING", 1)) Order.Unknown_security;
         "unknown sell security"
         >:: rejection_test (Order.Sell ("MISSING", 1)) Order.Unknown_security;
         "insufficient cash"
         >:: rejection_test (Order.Buy ("XYZ", 9)) Order.Insufficient_cash;
         "insufficient shares"
         >:: rejection_test (Order.Sell ("XYZ", 3)) Order.Insufficient_shares;
         "sale funds later purchase" >:: funding_test false;
         "reversing orders changes outcome" >:: funding_test true;
         "continue after all rejection types" >:: continue_after_rejection_test;
         "empty order list" >:: empty_orders_test;
         "missing valuation price" >:: missing_valuation_price_test;
         "accounting reference through Market" >:: accounting_reference_test;
         "independent multi-date accounting" >:: independent_accounting_test;
       ]

let () = run_test_tt_main tests
