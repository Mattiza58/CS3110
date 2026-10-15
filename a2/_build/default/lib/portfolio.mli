(** Immutable portfolio accounting. All monetary amounts are integer cents and
    quantities are whole shares. These operations perform no file or terminal
    I/O. *)

type t
(** A portfolio with nonnegative cash and holdings. Its representation is
    hidden. *)

val create : int -> (t, string) result
(** [create initial_cash] starts a portfolio with [initial_cash] cents and no
    shares. Returns [Error message] when [initial_cash] is not strictly
    positive. *)

val cash : t -> int
(** [cash portfolio] is the available cash in cents. *)

val holdings : t -> (string * int) list
(** [holdings portfolio] contains each held security exactly once with its
    positive share quantity. Zero holdings are omitted. Order is unspecified. *)

val shares : t -> string -> int
(** [shares portfolio security] is the held share count, or zero if absent. *)

val apply_order : t -> (string * int) list -> Order.t -> t * Order.outcome
(** [apply_order portfolio prices order] executes an order at the supplied
    current prices or returns the unchanged portfolio with a rejection reason.
    Nonpositive quantities, securities absent from [prices], insufficient cash,
    and insufficient shares cause rejection. [prices] must be a valid market
    row's security/price associations, with unique names and positive cent
    prices. The input portfolio is never mutated. *)

val apply_orders :
  t -> (string * int) list -> Order.t list -> t * Order.outcome list
(** [apply_orders portfolio prices orders] processes orders from left to right,
    using each resulting portfolio for the next order. Sale proceeds are
    available to later purchases. Rejection does not stop processing. Outcomes
    appear in the same order as the proposed orders. [prices] has the same
    requirements as for [apply_order]. *)

val value : t -> (string * int) list -> (int, string) result
(** [value portfolio prices] is cash plus holdings valued at the supplied
    current cent prices. Returns [Error message] if a held security has no
    price. Prices must have unique names and strictly positive values. *)
