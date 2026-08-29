open! Core
open Yocaml

type t

val id : t -> string
val validate : Data.t -> t Data.Validation.validated_value
val normalize : t -> (string * Data.t) list
