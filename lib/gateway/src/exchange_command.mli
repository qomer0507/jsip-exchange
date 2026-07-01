open! Core
open Jsip_types

module Verb : sig
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

val parse : ?default_participant:Participant.t -> string -> t Or_error.t
