(** [digits text] is true exactly when [text] is nonempty and consists entirely
    of decimal digits. *)
let digits text =
  String.length text > 0
  && String.for_all (fun character -> character >= '0' && character <= '9') text

(** [convert_cents text] parses one or more decimal digits, a dot, and exactly
    two decimal digits. Returns integer cents or an error for other formats or
    amounts outside the integer range. Zero is allowed; callers requiring
    positive amounts must check it. *)
let convert_cents text =
  let invalid = Error "Expected digits with exactly two decimal places" in
  match String.split_on_char '.' text with
  | [ dollars; cents ]
    when digits dollars && String.length cents = 2 && digits cents -> (
      match int_of_string_opt (dollars ^ cents) with
      | Some amount -> Ok amount
      | None -> Error "Amount is outside the supported integer-cent range")
  | _ -> invalid

(** [format cents] formats nonnegative cents with exactly two decimal places,
    without a dollar sign or thousands separators. Raises [Invalid_argument] if
    [cents] is negative. *)
let format cents =
  if cents < 0 then invalid_arg "Money.format requires nonnegative cents";
  Printf.sprintf "%d.%02d" (cents / 100) (cents mod 100)
