(** Batteries-based command-line parsing. Validation that requires market
    securities is left to strategy initialization after loading the file. *)

type strategy =
  | Cash
  | Buy_and_hold
  | Momentum

type t = private {
  market_file : string;
  strategy : strategy;
  equity_file : string;
  initial_cash : int;
  options : (string * string) list;
}
(** A validated command with positive initial cash in integer cents. *)

val parse : unit -> t
(** Parse [Sys.argv] once with [BatOptParse]. Check exactly three positional
    arguments, a recognized strategy, and a required positive two-decimal cash
    amount before any market file is opened. Options use names without dashes.
    Built-in [-h]/[--help] prints help and exits successfully. Invalid arguments
    print usage and a specific error, then exit unsuccessfully. *)
