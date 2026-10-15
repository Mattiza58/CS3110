(** [simulate command market] runs the strategy selected by the validated
    [command] on the loaded [market], using the command's initial cents and
    options. Returns the completed result or an initialization/accounting error.
    Performs no file or terminal I/O. *)
let simulate (command : Command.t) market =
  let run =
    match command.strategy with
    | Command.Cash ->
        Backtest.run ~name:Strategy.Cash.name ~init:Strategy.Cash.init
          ~step:Strategy.Cash.step
    | Command.Buy_and_hold ->
        Backtest.run ~name:Strategy.Buy_and_hold.name
          ~init:Strategy.Buy_and_hold.init ~step:Strategy.Buy_and_hold.step
    | Command.Momentum ->
        Backtest.run ~name:Strategy.Momentum.name ~init:Strategy.Momentum.init
          ~step:Strategy.Momentum.step
  in
  run ~options:command.options market ~initial_cash:command.initial_cash

(** [execute command] loads the requested market, runs the selected strategy,
    and writes its equity CSV. Returns the complete summary on success or an
    error message on failure. Requires a validated [command]. An existing output
    file is overwritten only after loading and simulation succeed. *)
let execute (command : Command.t) =
  match Market.load command.market_file with
  | Error message -> Error message
  | Ok market -> (
      match simulate command market with
      | Error message -> Error message
      | Ok result -> (
          match Report.write command.equity_file result with
          | Error message -> Error message
          | Ok () -> Ok (Report.render result)))

(** [run ()] parses command-line arguments, loads the market, runs the selected
    strategy, writes its equity CSV, and prints its complete summary. Errors are
    reported on standard error with an unsuccessful exit status. Help exits
    successfully before market or output files are opened. *)
let run () =
  let command = Command.parse () in
  match execute command with
  | Ok summary -> print_string summary
  | Error message ->
      prerr_endline ("Error: " ^ message);
      exit 1
