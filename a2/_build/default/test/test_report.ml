open OUnit2
module Backtest = A2.Backtest
module Market = A2.Market
module Money = A2.Money
module Order = A2.Order
module Report = A2.Report
module Strategy = A2.Strategy

let get_ok = function
  | Ok value -> value
  | Error message -> assert_failure message

let money_parsing_test _ =
  List.iter
    (fun (text, expected) ->
      assert_equal (Ok expected) (Money.convert_cents text))
    [ ("0.00", 0); ("0.01", 1); ("7.05", 705); ("0010.99", 1099) ];
  List.iter
    (fun text ->
      match Money.convert_cents text with
      | Error _ -> ()
      | Ok _ -> assert_failure ("Expected invalid money format: " ^ text))
    [
      "";
      "1";
      ".01";
      "1.";
      "1.0";
      "1.000";
      "+1.00";
      "-1.00";
      "1_000.00";
      "1e2.00";
      "0x10.00";
      " 1.00";
      "1.00 ";
      "1. 1";
      "1.00.00";
      "999999999999999999999999999.99";
    ]

let money_formatting_test _ =
  List.iter
    (fun (cents, expected) -> assert_equal expected (Money.format cents))
    [ (0, "0.00"); (1, "0.01"); (10, "0.10"); (100, "1.00"); (10005, "100.05") ];
  assert_raises (Invalid_argument "Money.format requires nonnegative cents")
    (fun () -> ignore (Money.format (-1)))

module Multiple_holdings : Strategy.S = struct
  type state = bool

  let name = "test-holdings"
  let init _ = Ok false

  let step done_buying _ =
    if done_buying then ([], true)
    else ([ Order.Buy ("ZED", 1); Order.Buy ("ALFA", 2) ], true)
end

let render_holdings_test _ =
  let market = get_ok (Market.load "../data/strategy-tiny.csv") in
  let result =
    get_ok
      (Backtest.run ~name:Multiple_holdings.name ~init:Multiple_holdings.init
         ~step:Multiple_holdings.step market ~initial_cash:2000)
  in
  assert_equal
    (String.concat "\n"
       [
         "Strategy: test-holdings";
         "Period: 2024-02-26 to 2024-03-06";
         "Initial cash: $20.00";
         "Final cash: $7.00";
         "Final holdings:";
         "  ALFA: 2 shares";
         "  ZED: 1 share";
         "Final portfolio value: $27.50";
         "Total return: 37.50%";
         "";
       ])
    (Report.render result)

let tests =
  "Money and Report"
  >::: [
         "strict money parsing" >:: money_parsing_test;
         "exact cent formatting" >:: money_formatting_test;
         "complete sorted holdings summary" >:: render_holdings_test;
       ]

let () = run_test_tt_main tests
