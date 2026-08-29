open! Core
open Yocaml

type t

module Stats : sig
  type t

  val id : t -> string
  val validate : Data.t -> t Data.Validation.validated_value
  val normalize : t -> (string * Data.t) list
end

include Required.DATA_READABLE with type t := t

val normalize : t -> (string * Data.t) list

(** Replace every [{{ chart:<id> }}] and [{{ stats:<id> }}] marker with an HTML
    comment so the Markdown renderer cannot interpret rendered templates as
    Markdown. Fails when a marker has no matching data or when chart or stats
    data is not placed. A stats group must be placed exactly once. *)
val protect_markers : t option -> content:string -> string

(** Replace protected comments in rendered HTML with charts and stats. *)
val render_markers
  :  t option
  -> content:string
  -> render_chart:(Chart.t -> string)
  -> render_stats:(Stats.t -> string)
  -> string
