(** Proposed whole-share orders and their processing outcomes. Orders contain no
    execution logic; Portfolio decides whether they can be executed. *)

(** [Buy (security, quantity)] and [Sell (security, quantity)] propose a trade.
    Quantities are whole shares. Constructors permit invalid quantities so that
    Portfolio can reject them when processing orders. *)
type t =
  | Buy of string * int
  | Sell of string * int

(** Reasons for rejecting an order without changing the portfolio. *)
type rejection =
  | Invalid_quantity
  | Unknown_security
  | Insufficient_cash
  | Insufficient_shares

(** The outcome of processing one order. *)
type outcome =
  | Executed
  | Rejected of rejection
