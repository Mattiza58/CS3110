(** Application entry point and orchestration. *)

val run : unit -> unit
(** Parse command-line arguments, load the market, run the selected strategy,
    write its equity CSV, and print its complete summary. Errors are reported on
    standard error with an unsuccessful exit status. Help exits successfully
    before market or output files are opened. *)
