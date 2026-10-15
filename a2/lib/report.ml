(** [render result] is the complete final summary, including strategy, period,
    initial cash, final cash, positive holdings, final value, and percentage
    return. Money and return have two decimal places. The string ends with a
    newline. No I/O. *)
let render (result : Backtest.t) =
  let holdings =
    Portfolio.holdings result.final_portfolio
    |> List.filter (fun (_, quantity) -> quantity > 0)
    |> List.sort (fun (left, _) (right, _) -> String.compare left right)
  in
  let holdings_text =
    match holdings with
    | [] -> "  none\n"
    | _ ->
        holdings
        |> List.map (fun (security, quantity) ->
            Printf.sprintf "  %s: %d %s\n" security quantity
              (if quantity = 1 then "share" else "shares"))
        |> String.concat ""
  in
  Printf.sprintf
    "Strategy: %s\n\
     Period: %s to %s\n\
     Initial cash: $%s\n\
     Final cash: $%s\n\
     Final holdings:\n\
     %sFinal portfolio value: $%s\n\
     Total return: %.2f%%\n"
    result.strategy result.initial_date result.final_date
    (Money.format result.initial_cash)
    (Money.format (Portfolio.cash result.final_portfolio))
    holdings_text
    (Money.format result.final_value)
    result.total_return

(** [write filename result] writes the exact [date,value] header and one row per
    simulation date, in order, using the recorded post-order portfolio values.
    Values have two decimal places with no dollar signs or separators. Returns
    an error identifying the output file if it cannot be opened or written. An
    existing output file is overwritten. *)
let write filename (result : Backtest.t) =
  let rows =
    [ "date"; "value" ]
    :: List.map
         (fun (snapshot : Backtest.snapshot) ->
           [ snapshot.date; Money.format snapshot.value ])
         result.history
  in
  try
    let channel = open_out_bin filename in
    Fun.protect
      ~finally:(fun () -> close_out_noerr channel)
      (fun () ->
        let csv = Csv.to_channel channel in
        Csv.output_all csv rows;
        Csv.close_out csv);
    Ok ()
  with Sys_error message ->
    Error (Printf.sprintf "Cannot write equity file %S: %s" filename message)
