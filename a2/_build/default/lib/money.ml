let digits text =
  String.length text > 0
  && String.for_all (fun character -> character >= '0' && character <= '9') text

let convert_cents text =
  let invalid = Error "Expected digits with exactly two decimal places" in
  match String.split_on_char '.' text with
  | [ dollars; cents ]
    when digits dollars && String.length cents = 2 && digits cents -> (
      match int_of_string_opt (dollars ^ cents) with
      | Some amount -> Ok amount
      | None -> Error "Amount is outside the supported integer-cent range")
  | _ -> invalid

let format cents =
  if cents < 0 then invalid_arg "Money.format requires nonnegative cents";
  Printf.sprintf "%d.%02d" (cents / 100) (cents mod 100)
