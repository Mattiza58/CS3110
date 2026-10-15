open OUnit2
module Market = A2.Market

(** [load filename] loads a valid market CSV for a test, failing the OUnit
    assertion if loading returns an error. *)
let load filename =
  match Market.load filename with
  | Ok market -> market
  | Error message -> assert_failure message

(** [with_csv contents test] writes [contents] to a temporary CSV, calls [test]
    with its filename, and removes the file even if the callback fails. *)
let with_csv contents test =
  let filename = Filename.temp_file "a2-market-" ".csv" in
  Fun.protect
    ~finally:(fun () -> Sys.remove filename)
    (fun () ->
      let channel = open_out_bin filename in
      Fun.protect
        ~finally:(fun () -> close_out_noerr channel)
        (fun () -> output_string channel contents);
      test filename)

(** Checks every handout date, header name, and exact cent price through the
    Market interface. *)
let handout_test _ =
  let market = load "../data/handout.csv" in
  assert_equal [ "ALFA"; "BETA" ] (Market.securities market);
  assert_equal
    Market.
      [
        { date = "2024-01-02"; prices = [ ("ALFA", 1000); ("BETA", 2500) ] };
        { date = "2024-01-03"; prices = [ ("ALFA", 1200); ("BETA", 2000) ] };
        { date = "2024-01-04"; prices = [ ("ALFA", 1100); ("BETA", 2100) ] };
      ]
    (Market.rows market)

(** Checks all five SPY rows, including their dates and exact integer-cent
    prices. *)
let spy_test _ =
  let market = load "../data/small-spy-5days.csv" in
  assert_equal [ "SPY" ] (Market.securities market);
  assert_equal
    [
      ("2008-09-15", [ ("SPY", 10461) ]);
      ("2008-09-16", [ ("SPY", 10635) ]);
      ("2008-09-17", [ ("SPY", 10158) ]);
      ("2008-09-18", [ ("SPY", 10459) ]);
      ("2008-09-19", [ ("SPY", 10812) ]);
    ]
    (List.map
       (fun (row : Market.row) -> (row.date, row.prices))
       (Market.rows market))

(** Checks header order, fractional-dollar prices, gaps between dates, and CRLF
    line endings on a valid temporary market. *)
let cents_and_order_test _ =
  with_csv
    "date,ZED,Q7,AAA\r\n\
     2024-02-29,0.01,7.05,100.99\r\n\
     2024-03-04,0.10,7.50,99.01\r\n" (fun filename ->
      let market = load filename in
      assert_equal [ "ZED"; "Q7"; "AAA" ] (Market.securities market);
      assert_equal
        Market.
          [
            {
              date = "2024-02-29";
              prices = [ ("ZED", 1); ("Q7", 705); ("AAA", 10099) ];
            };
            {
              date = "2024-03-04";
              prices = [ ("ZED", 10); ("Q7", 750); ("AAA", 9901) ];
            };
          ]
        (Market.rows market))

(** Checks a single-security, single-date file without a trailing newline. *)
let one_row_test _ =
  with_csv "date,ONLY\n2024-01-02,1.00" (fun filename ->
      let market = load filename in
      assert_equal [ "ONLY" ] (Market.securities market);
      assert_equal
        Market.[ { date = "2024-01-02"; prices = [ ("ONLY", 100) ] } ]
        (Market.rows market))

(** [historical_test filename security_count row_count first_date first_price]
    checks those independently supplied expectations and each row's header
    associations. Requires a nonempty valid market at [filename]; prices are
    cents. *)
let historical_test filename security_count row_count first_date first_price _ =
  let market = load filename in
  assert_equal security_count (List.length (Market.securities market));
  let rows = Market.rows market in
  assert_equal row_count (List.length rows);
  let first : Market.row = List.hd rows in
  assert_equal first_date first.date;
  assert_equal first_price (List.hd first.prices);
  List.iter
    (fun (row : Market.row) ->
      assert_equal (Market.securities market) (List.map fst row.prices))
    rows

(** Checks that a nonexistent market filename produces an error identifying that
    file. *)
let missing_file_test _ =
  with_csv "" (fun filename ->
      let missing = filename ^ ".missing" in
      match Market.load missing with
      | Ok _ -> assert_failure "Expected an error for a missing file"
      | Error message ->
          assert_bool "Error identifies the input file"
            (String.starts_with
               ~prefix:(Printf.sprintf "Cannot load market file %S:" missing)
               message))

let tests =
  "Market CSV loading"
  >::: [
         "handout prices" >:: handout_test;
         "single security" >:: spy_test;
         "exact cents and header order" >:: cents_and_order_test;
         "one row without final newline" >:: one_row_test;
         "medium historical file"
         >:: historical_test "../data/medium-tech-2007.csv" 5 251 "2007-01-03"
               ("AAPL", 1073);
         "large historical file"
         >:: historical_test "../data/large-dotcom-ca2000.csv" 20 748
               "1999-01-04" ("AAPL", 132);
         "missing input file" >:: missing_file_test;
       ]

let () = run_test_tt_main tests
