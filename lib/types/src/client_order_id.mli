open! Core

type t = int [@@deriving sexp, bin_io, compare, equal, hash]

include Comparable.S with type t := t
include Hashable.S with type t := t

val of_int : int -> t
val to_int : t -> int
val to_string : t -> string
val of_string : string -> t
