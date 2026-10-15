open OUnit2
module Order = A2.Order
module Strategy = A2.Strategy

(** [get_ok result] extracts an [Ok] value or fails the OUnit assertion with the
    message carried by [Error]. *)
let get_ok = function
  | Ok value -> value
  | Error message -> assert_failure message

(** [context ~cash ~options securities] is an initialization context for the
    named header-order securities. Cash is positive integer cents; defaults are
    1000 cents and no options. *)
let context ?(cash = 1000) ?(options = []) securities : Strategy.init_context =
  { securities; initial_cash = cash; options }

(** [observation ~cash ~holdings day prices] is a January 2024 observation for
    [day], with current cent prices and whole-share holdings. Requires a valid
    January day and a valid portfolio/price view; defaults are 1000 cents and no
    holdings. *)
let observation ?(cash = 1000) ?(holdings = []) day prices :
    Strategy.observation =
  { date = Printf.sprintf "2024-01-%02d" day; prices; cash; holdings }

(** Checks exact hold-option validation for buy-and-hold and that Cash/Momentum
    ignore irrelevant hold options. *)
let option_validation_test _ =
  List.iter
    (fun options ->
      match Strategy.Buy_and_hold.init (context ~options [ "ZED" ]) with
      | Error message ->
          assert_bool "Helpful option error" (String.length message > 0)
      | Ok _ -> assert_failure "Expected invalid --hold to be rejected")
    [ []; [ ("hold", "zed") ]; [ ("hold", "MISSING") ]; [ ("hold", "") ] ];
  ignore
    (get_ok
       (Strategy.Buy_and_hold.init
          (context ~options:[ ("hold", "ZED") ] [ "ZED" ])));
  let unrelated_hold = context ~options:[ ("hold", "MISSING") ] [ "ZED" ] in
  ignore (get_ok (Strategy.Cash.init unrelated_hold));
  ignore (get_ok (Strategy.Momentum.init unrelated_hold))

(** Checks the three required command-line strategy names exposed by the sealed
    modules. *)
let names_test _ =
  assert_equal "cash" Strategy.Cash.name;
  assert_equal "buy-and-hold" Strategy.Buy_and_hold.name;
  assert_equal "momentum" Strategy.Momentum.name

(** Checks that Cash proposes no liquidation or other orders even when the
    observation contains holdings. *)
let cash_with_holdings_test _ =
  let state = get_ok (Strategy.Cash.init (context [ "A" ])) in
  let orders, _ =
    Strategy.Cash.step state
      (observation ~cash:0 ~holdings:[ ("A", 3) ] 1 [ ("A", 900) ])
  in
  assert_equal [] orders

(** Checks that buy-and-hold never retries an unaffordable first-date purchase
    when a later price becomes affordable. *)
let buy_unaffordable_test _ =
  let state =
    get_ok
      (Strategy.Buy_and_hold.init (context ~options:[ ("hold", "A") ] [ "A" ]))
  in
  let orders, state =
    Strategy.Buy_and_hold.step state (observation 1 [ ("A", 1001) ])
  in
  assert_equal [] orders;
  let orders, _ =
    Strategy.Buy_and_hold.step state (observation 2 [ ("A", 1) ])
  in
  assert_equal [] orders

(** Checks that a positive-gain tie uses initialization header order even when
    observations list securities in another order. *)
let momentum_header_tie_test _ =
  let state = get_ok (Strategy.Momentum.init (context [ "ZED"; "ALFA" ])) in
  let orders, state =
    Strategy.Momentum.step state (observation 1 [ ("ALFA", 100); ("ZED", 100) ])
  in
  assert_equal [] orders;
  let orders, _ =
    Strategy.Momentum.step state (observation 2 [ ("ALFA", 200); ("ZED", 200) ])
  in
  assert_equal [ Order.Buy ("ZED", 5) ] orders

(** Checks selection by absolute cent gain rather than percentage gain. *)
let momentum_absolute_gain_test _ =
  let state =
    get_ok (Strategy.Momentum.init (context ~cash:2000 [ "A"; "B" ]))
  in
  let _, state =
    Strategy.Momentum.step state
      (observation ~cash:2000 1 [ ("A", 100); ("B", 1000) ])
  in
  let orders, _ =
    Strategy.Momentum.step state
      (observation ~cash:2000 2 [ ("A", 120); ("B", 1030) ])
  in
  assert_equal [ Order.Buy ("B", 1) ] orders

(** Checks that an unaffordable target is remembered through a decline and is
    not retried on a later affordable increase. *)
let momentum_unaffordable_target_test _ =
  let state =
    get_ok (Strategy.Momentum.init (context ~cash:100 [ "A"; "B" ]))
  in
  let advance state day prices =
    let orders, state =
      Strategy.Momentum.step state (observation ~cash:100 day prices)
    in
    assert_equal [] orders;
    state
  in
  let state = advance state 1 [ ("A", 200); ("B", 300) ] in
  let state = advance state 2 [ ("A", 250); ("B", 300) ] in
  let state = advance state 3 [ ("A", 50); ("B", 100) ] in
  ignore (advance state 4 [ ("A", 75); ("B", 100) ])

(** Checks liquidation when a new target is unaffordable and retention of that
    target after it becomes affordable. *)
let momentum_unaffordable_switch_test _ =
  let state =
    get_ok (Strategy.Momentum.init (context ~cash:100 [ "A"; "B" ]))
  in
  let _, state =
    Strategy.Momentum.step state
      (observation ~cash:100 1 [ ("A", 40); ("B", 500) ])
  in
  let orders, state =
    Strategy.Momentum.step state
      (observation ~cash:100 2 [ ("A", 50); ("B", 500) ])
  in
  assert_equal [ Order.Buy ("A", 2) ] orders;
  let orders, state =
    Strategy.Momentum.step state
      (observation ~cash:0 ~holdings:[ ("A", 2) ] 3 [ ("A", 50); ("B", 1000) ])
  in
  assert_equal [ Order.Sell ("A", 2) ] orders;
  let orders, state =
    Strategy.Momentum.step state
      (observation ~cash:100 4 [ ("A", 50); ("B", 75) ])
  in
  assert_equal [] orders;
  let orders, _ =
    Strategy.Momentum.step state
      (observation ~cash:100 5 [ ("A", 50); ("B", 80) ])
  in
  assert_equal [] orders

(** Checks that previous prices update on declining days, so later gains compare
    only with the immediately preceding row. *)
let momentum_updates_previous_test _ =
  let state = get_ok (Strategy.Momentum.init (context [ "A"; "B" ])) in
  let _, state =
    Strategy.Momentum.step state (observation 1 [ ("A", 100); ("B", 100) ])
  in
  let orders, state =
    Strategy.Momentum.step state (observation 2 [ ("A", 200); ("B", 110) ])
  in
  assert_equal [ Order.Buy ("A", 5) ] orders;
  let orders, state =
    Strategy.Momentum.step state
      (observation ~cash:0 ~holdings:[ ("A", 5) ] 3 [ ("A", 100); ("B", 100) ])
  in
  assert_equal [] orders;
  let orders, _ =
    Strategy.Momentum.step state
      (observation ~cash:0 ~holdings:[ ("A", 5) ] 4 [ ("A", 150); ("B", 120) ])
  in
  assert_equal [] orders

(** Checks sales of every held security before a new-target purchase sized using
    all sale proceeds and current cash. *)
let momentum_liquidates_all_test _ =
  let state =
    get_ok (Strategy.Momentum.init (context ~cash:305 [ "Z"; "A"; "Q" ]))
  in
  let _, state =
    Strategy.Momentum.step state
      (observation ~cash:305 1 [ ("Z", 100); ("A", 100); ("Q", 100) ])
  in
  let orders, _ =
    Strategy.Momentum.step state
      (observation ~cash:5
         ~holdings:[ ("Z", 2); ("A", 1) ]
         2
         [ ("Z", 110); ("A", 120); ("Q", 130) ])
  in
  assert_equal
    [ Order.Sell ("Z", 2); Order.Sell ("A", 1); Order.Buy ("Q", 2) ]
    orders

(** Checks deterministic replay and branching from earlier opaque states without
    mutation of those states. *)
let momentum_state_is_immutable_test _ =
  let initial = get_ok (Strategy.Momentum.init (context [ "A"; "B" ])) in
  let _, previous =
    Strategy.Momentum.step initial (observation 1 [ ("A", 100); ("B", 100) ])
  in
  let next = observation 2 [ ("A", 200); ("B", 100) ] in
  let orders, _ = Strategy.Momentum.step previous next in
  let replayed, _ = Strategy.Momentum.step previous next in
  assert_equal [ Order.Buy ("A", 5) ] orders;
  assert_equal orders replayed;
  let other, _ =
    Strategy.Momentum.step previous (observation 2 [ ("A", 100); ("B", 200) ])
  in
  assert_equal [ Order.Buy ("B", 5) ] other;
  let first, _ = Strategy.Momentum.step initial next in
  assert_equal [] first

let tests =
  "Strategies"
  >::: [
         "Cash" >::: [ "no liquidation" >:: cash_with_holdings_test ];
         "Buy-and-hold"
         >::: [
                "options" >:: option_validation_test;
                "unaffordable first day" >:: buy_unaffordable_test;
              ];
         "Momentum"
         >::: [
                "header-order ties" >:: momentum_header_tie_test;
                "absolute gains" >:: momentum_absolute_gain_test;
                "remember unaffordable target"
                >:: momentum_unaffordable_target_test;
                "sell despite unaffordable new target"
                >:: momentum_unaffordable_switch_test;
                "update prices after no gain" >:: momentum_updates_previous_test;
                "liquidate all holdings" >:: momentum_liquidates_all_test;
                "immutable deterministic state"
                >:: momentum_state_is_immutable_test;
              ];
         "strategy names" >:: names_test;
       ]

let () = run_test_tt_main tests
