(** Application entry point and orchestration. *)

val run : unit -> unit
(** [run ()] parses command-line arguments, loads the market, runs the selected
    strategy, writes its equity CSV, and prints its complete summary. Errors are
    reported on standard error with an unsuccessful exit status. Help exits
    successfully before market or output files are opened. *)
