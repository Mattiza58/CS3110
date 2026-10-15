type t =
  | Buy of string * int
  | Sell of string * int

type rejection =
  | Invalid_quantity
  | Unknown_security
  | Insufficient_cash
  | Insufficient_shares

type outcome =
  | Executed
  | Rejected of rejection
