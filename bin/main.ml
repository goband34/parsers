open Containers

type redux_item =
  | Terminal of string
  | NonTerminal of string
  | EndOfInput
type redux = redux_item list
type reduction_rule = string * redux

type grammar = (string, redux) Hashtbl.t
let grammar_of_list xs =
  let res = Hashtbl.create 10 in
  List.iter (fun (s, r) -> Hashtbl.add res s r) xs;
  res

let test_grammar: grammar = grammar_of_list [
  ("E", [NonTerminal "E"; Terminal "*"; NonTerminal "B"]);
  ("E", [NonTerminal "E"; Terminal "+"; NonTerminal "B"]);
  ("E", [NonTerminal "B"]);
  ("B", [Terminal "0"]);
  ("B", [Terminal "1"]);
]

(* E -> x . y *)
module Item = struct
  type t = reduction_rule * int

  let hash = Hashtbl.hash
  let equal (r, n) (r', n') =
    n = n' && (
      let s, r = r in
      let s', r' = r' in
      String.equal s s' && (
        List.equal (fun r r' ->
            match r,r' with
            | Terminal s, Terminal s' | NonTerminal s, NonTerminal s' -> String.equal s s'
            | EndOfInput, EndOfInput -> true
            | _ -> false
          ) r r'
      )
    )

  let to_string (rrule, n) =
    let rhs_to_string rhs =
      List.fold_left (fun acc x -> match x with | NonTerminal s | Terminal s -> acc ^ s | EndOfInput -> acc) "" rhs
    in
    let rrule_to_string (lhs, rhs) =
      Printf.sprintf "%s -> %s" lhs (rhs_to_string rhs)
    in
    Printf.sprintf "Position %d, %s" n (rrule_to_string rrule) 
end
module ItemSet = CCHashSet.Make(Item)

let closure (it_s: ItemSet.t): ItemSet.t =
  let rec loop () =
    let old_cardinality = ItemSet.cardinal it_s in
    ItemSet.iter (fun ((_, rhs), i) ->
        match List.nth rhs i with
        | NonTerminal s ->
            let associated_rules = Hashtbl.find_all test_grammar s in
            List.iter (fun rule -> ItemSet.insert it_s ((s, rule), 0)) associated_rules 
        | _ -> ()
      ) it_s;
    if ItemSet.cardinal it_s <> old_cardinality then
      loop ()
  in
  loop ();
  it_s

let () =
  let test = ItemSet.create 10 in
  ItemSet.insert test (("S", [NonTerminal "E"; EndOfInput]), 0); 
  closure test |> ItemSet.iter (fun i -> Item.to_string i |> print_endline)
