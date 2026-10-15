open BatOptParse

type strategy =
  | Cash
  | Buy_and_hold
  | Momentum

type t = {
  market_file : string;
  strategy : strategy;
  equity_file : string;
  initial_cash : int;
  options : (string * string) list;
}

let parse () =
  let parser =
    OptParser.make
      ~usage:
        "%prog MARKET.csv STRATEGY EQUITY.csv --cash DOLLARS [--hold SYMBOL]"
      ~description:
        "Backtest cash, buy-and-hold, or momentum against historical prices."
      ()
  in
  let cash = StdOpt.str_option ~metavar:"DOLLARS" () in
  let hold = StdOpt.str_option ~metavar:"SYMBOL" () in
  OptParser.add parser ~long_name:"cash"
    ~help:"positive initial cash, e.g. 10000.00" cash;
  OptParser.add parser ~long_name:"hold" ~help:"security bought by buy-and-hold"
    hold;
  let fail message =
    OptParser.error parser message;
    exit 1
  in
  let positional = OptParser.parse_argv parser in
  match positional with
  | [ market_file; strategy; equity_file ] ->
      let strategy =
        match strategy with
        | "cash" -> Cash
        | "buy-and-hold" -> Buy_and_hold
        | "momentum" -> Momentum
        | unknown ->
            fail
              (Printf.sprintf
                 "Unknown strategy %S; choose cash, buy-and-hold, or momentum"
                 unknown)
      in
      let initial_cash =
        match Opt.opt cash with
        | None -> fail "Missing required --cash DOLLARS"
        | Some text -> (
            match Money.convert_cents text with
            | Ok cents when cents > 0 -> cents
            | _ ->
                fail
                  "--cash must be a positive amount with exactly two decimal \
                   places (e.g. 10000.00)")
      in
      let options =
        match Opt.opt hold with
        | None -> []
        | Some security -> [ ("hold", security) ]
      in
      { market_file; strategy; equity_file; initial_cash; options }
  | _ ->
      fail
        "Expected exactly three positional arguments: MARKET.csv STRATEGY \
         EQUITY.csv"
