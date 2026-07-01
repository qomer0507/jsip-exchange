open! Core
open Jsip_types

module Verb = struct
  type t =
    | Buy
    | Sell
    | Book
    | Subscribe
  [@@deriving sexp, compare, equal, enumerate, string]
end

type t =
  | Submit of Order.Request.t
  | Book of Symbol.t
  | Subscribe of Symbol.t
[@@deriving sexp_of]

let default_participant = Participant.of_string "anonymous"

let verb_of_string s =
  Verb.of_string (String.capitalize (String.lowercase s))
;;

let parse_symbol symbol_str =
  try Ok (Symbol.of_string symbol_str) with
  | exn ->
    Error
      [%string
        "invalid symbol: %{symbol_str}\nexception: %{Exn.to_string exn}"]
;;

let parse_size size_str =
  match Int.of_string_opt size_str with
  | Some n when n > 0 -> Ok (Size.of_int n)
  | Some _ -> Error "size must be positive"
  | None -> Error [%string "invalid size: %{size_str}"]
;;

let parse_price price_str =
  try Ok (Price.of_string price_str) with
  | exn ->
    Error
      [%string
        "invalid price: %{price_str}\nexception: %{Exn.to_string exn}"]
;;

let parse_client_order_id client_order_id_str =
  try Ok (Client_order_id.of_string client_order_id_str) with
  | exn ->
    Error
      [%string
        "invalid client_order_id: %{client_order_id_str}\n\
         exception: %{Exn.to_string exn}"]
;;

let parse_time_in_force tif_str =
  try Ok (Time_in_force.of_string tif_str) with
  | exn ->
    Error
      [%string
        "unknown time-in-force: %{tif_str} (expected \
         %{Time_in_force.all_str})\n\
         exception: %{Exn.to_string exn}"]
;;

let parse_participant rest ~default =
  match rest with
  | "as" :: name :: _ | "AS" :: name :: _ -> Ok (Participant.of_string name)
  | [] -> Ok default
  | _ ->
    let trailing = String.concat ~sep:" " rest in
    Error [%string "unexpected trailing arguments: %{trailing}"]
;;

let parse_submit side rest ~default_participant =
  let open Result.Let_syntax in
  match rest with
  | client_id_str :: symbol_str :: size_str :: price_str :: rest ->
    let%bind client_order_id = parse_client_order_id client_id_str in
    let%bind symbol = parse_symbol symbol_str in
    let%bind size = parse_size size_str in
    let%bind price = parse_price price_str in
    let%bind time_in_force, rest =
      match rest with
      | tif_str :: rest' ->
        (match String.uppercase tif_str with
         | "AS" -> Ok (Time_in_force.Day, rest)
         | _ ->
           let%map time_in_force = parse_time_in_force tif_str in
           time_in_force, rest')
      | [] -> Ok (Time_in_force.Day, [])
    in
    let%bind participant =
      parse_participant rest ~default:default_participant
    in
    Ok
      (Submit
         ({ symbol
          ; participant
          ; side
          ; price
          ; size
          ; time_in_force
          ; client_order_id
          }
          : Order.Request.t))
  | _ ->
    Error
      [%string
        "expected: BUY|SELL <symbol> <size> <price> \
         [%{Time_in_force.all_str}] [as <name>]"]
;;

let parse_book rest =
  match rest with
  | [ symbol_str ] ->
    Result.map (parse_symbol symbol_str) ~f:(fun symbol -> Book symbol)
  | _ -> Error "expected: BOOK <symbol>"
;;

let parse_subscribe rest =
  match rest with
  | [ symbol_str ] ->
    Result.map (parse_symbol symbol_str) ~f:(fun symbol -> Subscribe symbol)
  | _ -> Error "expected: SUBSCRIBE <symbol>"
;;

let to_or_error result = Result.map_error result ~f:Error.of_string

let parse ?(default_participant = default_participant) line =
  let line = String.strip line in
  if String.is_empty line
  then Or_error.error_string "empty command"
  else (
    let parts =
      String.split line ~on:' ' |> List.filter ~f:(Fn.non String.is_empty)
    in
    match parts with
    | [] -> Or_error.error_string "empty command"
    | verb_str :: rest ->
      let open Or_error.Let_syntax in
      let%bind verb =
        Or_error.try_with (fun () -> verb_of_string verb_str)
      in
      (match verb with
       | Buy -> parse_submit Buy rest ~default_participant |> to_or_error
       | Sell -> parse_submit Sell rest ~default_participant |> to_or_error
       | Book -> parse_book rest |> to_or_error
       | Subscribe -> parse_subscribe rest |> to_or_error))
;;
