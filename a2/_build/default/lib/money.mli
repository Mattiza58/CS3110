(** Exact parsing and formatting of nonnegative integer-cent amounts. *)

val convert_cents : string -> (int, string) result
(** [convert_cents text] parses one or more decimal digits, a dot, and exactly
    two decimal digits. Returns integer cents or an error for other formats or
    amounts outside the integer range. Zero is allowed; callers requiring
    positive amounts must check it. *)

val format : int -> string
(** [format cents] formats nonnegative cents with exactly two decimal places,
    without a dollar sign or thousands separators. Raises [Invalid_argument] if
    [cents] is negative. *)
