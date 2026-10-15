
let opening =
  print_endline
    "\n\
     ///////////////////////////////////////////////// \n\n\
     HELLO! Welcome to Raise a G.O.A.T.!\n\n\
     Did you ever want to raise the next Messi, MJ, or uhhhh maybe Ronaldo??? \
     Well NO! I'm talking about raising actual goats, like the animal, to then\n\
     BECOME the next star athlete, musician, or CS 3110 programmong G.O.A.T. \
     Can a goat put a ball in a net, of course it can! Can a goat play guitar \
     like Eddie Van Halen? Of course it can!\n\
     Can a goat learn OCaml? NAH! It's a goat, it learns OGoat instead.\n\n\
    \  \n\
     Enter a name for your chosen G.O.A.T. (make it a good one): "

let pet_name = read_line ()

(** Variant corresponding to a pet's mood *)
type mood =
  | Hungry
  | Sleepy
  | Lonely
  | Delighted
  | Content

type goat = {
  name : string;
  fullness : int;
  happiness : int;
  energy : int;
  mood : mood;
}
(** *)

let newPet =
  {
    name = pet_name;
    fullness = 50;
    happiness = 50;
    energy = 50;
    mood = Content;
  }

(* [calc_wellness_score] pet returns the integer average of the [pet]'s
   fullness, happines, and energy levels *)
let calc_wellness_score pet = (pet.fullness + pet.happiness + pet.energy) / 3

(** [determine_mood pet] returns the mood of the [pet] *)
let determine_mood pet =
  let wellness = calc_wellness_score pet in
  if pet.fullness <= 20 then Hungry
  else if pet.energy <= 20 then Sleepy
  else if pet.happiness <= 20 then Lonely
  else if wellness <= 20 then Delighted
  else Content

(** [calc_wellness fullness energy happiness] also returns the interage average
    of a pet's fullness, energy, and happiness by raw int values without needing
    to pass a pet as an argument *)
let calc_wellness fullness energy happiness =
  (fullness + happiness + energy) / 3

(** [determine_pet_mood fullness energy happiness] also returns a pet's mood by
    raw int values rather than needing to pass pet as an argument *)
let determine_pet_mood fullness energy happiness =
  let wellness = calc_wellness fullness energy happiness in
  if fullness <= 20 then Hungry
  else if energy <= 20 then Sleepy
  else if happiness <= 20 then Lonely
  else if wellness <= 20 then Delighted
  else Content

(** [moodString pet] determines and returns a string by pattern matching a
    [pet]'s mood with its corresponding string *)
let moodString pet =
  match pet.mood with
  | Hungry -> "Hungry"
  | Sleepy -> "Sleepy"
  | Lonely -> "Lonely"
  | Delighted -> "Delighted"
  | Content -> "Content"

(**[feed pet] performs a feed action by creating and returning a copy of the
   [pet] with updated stats. NOTE: This is similar to the action function, but
   specifically for the feed action. *)
let feed pet =
  let pet = pet in
  {
    pet with
    fullness = pet.fullness + 25;
    happiness = pet.happiness + 5;
    energy = pet.energy - 5;
    mood = determine_mood pet;
  }

(** [action pet f_level h_level e_level] returns a copy of [pet] with updated
    fullness, happiness, and energy levels based on the inputs [f_level],
    [h_level], [e_level] corresponding to a pet's care action *)
let action pet f_level h_level e_level =
  let pet = pet in
  {
    pet with
    fullness = pet.fullness + f_level;
    happiness = pet.happiness + h_level;
    energy = pet.energy - e_level;
  }

(** [get_lucky_number ()] prompts the user for an integer and returns it. If the
    user enters a non-integer, the function prints a message and prompts again.
*)
let rec get_lucky_number () =
  try int_of_string (read_line ())
  with Failure _ ->
    print_endline "Please enter a valid integer.";
    get_lucky_number ()

(** [print_lucky_number] prints and prompts the user to input an integer value
    and calls get_lucky_number()*)
let print_lucky_number =
  print_endline
    "\n\
     ///////////////////////////////////////\n\
     Every goat MUST have a lucky number! Enter its lucky number!";
  Random.init (get_lucky_number ())

(** [print_lucky_number pet rand] pattern matches [rand] with its corresponding
    value, prints a message, and then calls action on the [pet] parameter to
    update its stats when needed *)
let random_event pet rand =
  match rand with
  | 0 ->
      print_endline
        "\n\
         -----\n\n\
         The sky is blue. The grass is green. The OCaml syntax highlighter is \
         red. Seems like nothing unusual happened\n";
      pet
  | 1 ->
      Printf.printf
        "\n\
         -----\n\n\
         Woah! %s has found some delicious tacos that were psuedo-randomly \
         generated from the sky! What a random coincidence!\n"
        pet.name;
      action pet 10 0 0
  | 2 ->
      Printf.printf
        "\n\
         -----\n\n\
         %s got the zoomies after thinking about a prelim. But wait, goats \
         don't have prelims, only sad Cornell students do! \n"
        pet.name;
      action pet 0 15 (-10)
  | 3 ->
      Printf.printf
        "\n\
         -----\n\n\
         After a long day of doing nothing, %s decided to just take a nap.\n"
        pet.name;
      action pet (-5) 0 15
  | 4 ->
      Printf.printf
        "\n\
         -----\n\n\
         %s forgot to document their beautiful OGoat code. What a minor \
         mishap, well, not to the grader. Wait what's a grader???... \n"
        pet.name;
      action pet 0 (-10) 0
  | _ -> pet

(** [main_loop name turn fullness happiness energy] runs the virtual-pet
    simulation beginning on turn [turn], with the pet named [name] having the
    given attribute values. *)
let rec main_loop name turn fullness happiness energy =
  let pet =
    {
      name;
      fullness =
        (if fullness < 0 then 0 else if fullness > 100 then 100 else fullness);
      happiness =
        (if happiness < 0 then 0 else if happiness > 100 then 100 else happiness);
      energy = (if energy < 0 then 0 else if energy > 100 then 100 else energy);
      mood = determine_pet_mood fullness happiness energy;
    }
  in

  print_endline
    "\n\
     Select a choice for your G.O.A.T.:\n\n\
    \  1. 'Feed' the goat.\n\n\
    \  2. 'Play' with the goat.\n\n\
    \  3. Let the goat 'Nap'.\n\n\
    \  4. Play 'Soccer' with your goat, just like Messi.\n\n\
    \  5. 'Check' the status of your goat, what are its stats?\n\n\
    \  6. 'End' the day.\n\n\
    \  \n\n\
    \  Make sure to type specifically ['Feed', 'Play', 'End', 'Soccer', \
     'Check', or 'End']. All other responses with be invalid:\n\n\
    \  Enter your action!: ";

  if turn <= 5 then
    let choice = read_line () in
    let updated_pet =
      match choice with
      | "Feed" ->
          Printf.printf
            "\n\
             //////////////////////////////\n\
             %s has been fed some delcious Morrison stir-fry. Perfect for its \
             stomach!\n"
            pet.name;
          random_event (feed pet) (Random.int 5)
      | "Play" ->
          print_endline
            "\n\
             /////////////////////////////////////////\n\
             You played with the goat! First it was some chess, then it turned \
             it into some ";
          random_event (action pet (-10) 20 (-15)) (Random.int 5)
      | "Nap" ->
          print_endline
            "\n\
             ///////////////////////////////////////\n\
             Mimimirrr, your goat is catching some z's. It needs that rest \
             after a long, tiring, painfully exhausting, horrible, downright \
             attrocious day of doing nothing.";
          random_event (action pet (-10) (-5) 25) (Random.int 5)
      | "Soccer" ->
          print_endline
            "\n\
             ///////////////////////////////////////\n\
             Unlike Argentina in the 2026 FIFA World Cup hosted by the USA, \
             Canada, and Mexico at Metlife Stadium, East Rutherford, NJ on \
             July 19th, 2026, your goat actually scored a goal!";
          random_event (action pet (-15) 30 (-25)) (Random.int 5)
      | "Check" ->
        Printf.printf
            "\n\
             /////////////////////////////////////////\n\
             Current Stats: Turn: %i, Fullness: %i, Happiness: %i, Energy: %i, \
             Mood: %s \n"
            turn pet.fullness pet.happiness pet.energy (moodString pet); Printf.printf "Turn %i" turn;
          pet
      | "End" -> pet
      | _ ->
          print_endline "Invalid Input | Please Try Again!";
          pet
    in
    let turn =
      match choice with
      | "Feed" -> turn + 1
      | "Play" -> turn + 1
      | "Nap" -> turn + 1
      | "Soccer" -> turn + 1
      | "Check" -> turn
      | "End" -> 6
      (* Easy way of ending the day*)
      | _ -> turn
    in

    main_loop updated_pet.name turn updated_pet.fullness updated_pet.happiness
      updated_pet.energy
  else
    let final_wellness = calc_wellness_score pet in
    let show_outcome =
      if pet.fullness = 0 || pet.happiness = 0 || pet.energy = 0 then
        "Just like Micheal Jackson said in P.Y.T. your GOAT needs some \
         immediate TLC. Suddenly your goat becomes mad. It's as if not giving \
         it tender, love, and care will make it not tender, loved, or cared. \
         Your goat decides as an act of revenge to become like prime 2012 \
         messi, and score so much goals as it cans."
      else if final_wellness >= 75 then
        "Your goat is thriving! It becomes 2022 Messi from the world cup, \
         transforming into a unstoppable menace, as if nothing could phase \
         him. In fact, your goat is going to lift the next world cup in 2030! \
         You better catch it!"
      else if final_wellness >= 55 then
        "Well, your goat is doing well. It's average, in fact so average I'm \
         afraid it can't be the greatest without being the best. So, instead, \
         it just transforms into an average, uhh, goat, like median of every \
         possible goat. Quite sad. "
      else if final_wellness >= 35 then
        "Your goat got pretty frazzled! In fact, it just transforms into 2016 \
         Messi after losing the Copa America final. It is very sad, how could \
         you let that happen to your GOAT."
      else
        "Your goat was so neglected, it sadly, and quite disapointly \
         transforms into 2026 Cristiano Ronaldo, a shadow of its former self. \
         How could you let your goat become that? Next time, never neglect it!"
    in
    Printf.printf
      "Final Report: Fullness: %i, Happiness: %i, Energy: %i, Wellness %i, \
       Mood: %s\n\
       %s"
      pet.fullness pet.happiness pet.energy (calc_wellness_score pet)
      (moodString pet) show_outcome

let main =
  print_endline
    "\n\
     /////////////////////////////////////////\n\
     NOW, it's time to raise your goat to become the G.O.A.T.:";
  main_loop newPet.name 1 50 50 50

let print_closing = print_endline "Thank you for playing!"
