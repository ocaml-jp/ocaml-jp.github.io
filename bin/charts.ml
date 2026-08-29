open! Core
open Yocaml

module Stat = struct
  type t =
    { label : string
    ; value : int
    ; unit : string
    ; note : string option
    }

  let validate =
    let open Data.Validation in
    record (fun fields ->
      let+ label = required fields "label" string
      and+ value = required fields "value" (int & positive)
      and+ unit = optional_or fields "unit" ~default:"" string
      and+ note = optional fields "note" string in
      { label; value; unit; note })
  ;;

  let normalize { label; value; unit; note } =
    Data.
      [ "label", string label
      ; "value", int value
      ; "unit", string unit
      ; "note", option string note
      ; "has_note", bool (Option.is_some note)
      ]
  ;;
end

module Stats = struct
  type t =
    { id : string
    ; label : string
    ; items : Stat.t list
    }

  let id stats = stats.id

  let validate =
    let open Data.Validation in
    record (fun fields ->
      let+ id = required fields "id" (Slug.validate & String.not_empty)
      and+ label = required fields "label" string
      and+ items = required fields "items" (list_of Stat.validate & non_empty) in
      { id; label; items })
  ;;

  let normalize { id; label; items } =
    Data.
      [ "id", string id
      ; "label", string label
      ; "items", list_of (fun item -> record (Stat.normalize item)) items
      ]
  ;;
end

type t =
  { title : string
  ; lead : string option
  ; stats : Stats.t list
  ; charts : Chart.t list
  }

let entity_name = "Charts"
let neutral = Metadata.required entity_name

let validate_unique_ids charts =
  match List.find_a_dup (List.map charts ~f:Chart.id) ~compare:String.compare with
  | None -> Ok ()
  | Some id -> Data.Validation.fail_with ~given:id "chart ids must be unique"
;;

let validate_unique_stats_ids stats =
  match List.find_a_dup (List.map stats ~f:Stats.id) ~compare:String.compare with
  | None -> Ok ()
  | Some id -> Data.Validation.fail_with ~given:id "stats ids must be unique"
;;

let validate data =
  let open Data.Validation in
  record
    (fun fields ->
       let+ title = required fields "title" string
       and+ lead = optional fields "lead" string
       and+ stats = optional_or fields "stats" ~default:[] (list_of Stats.validate)
       and+ charts = required fields "charts" (list_of Chart.validate & non_empty) in
       { title; lead; stats; charts })
    data
  |> Result.bind ~f:(fun charts ->
    Result.all_unit
      [ validate_unique_ids charts.charts; validate_unique_stats_ids charts.stats ]
    |> Result.map ~f:(fun () -> charts))
;;

let normalize { title; lead; stats; charts = _ } =
  Data.
    [ "title", string title
    ; "lead", option string lead
    ; "has_lead", bool (Option.is_some lead)
    ; "stats", list_of (fun stats -> record (Stats.normalize stats)) stats
    ; "has_stats", bool (not (List.is_empty stats))
    ]
;;

let marker_prefix = "{{ chart:"
let marker_suffix = "}}"
let protected_marker_prefix = "<!-- ocaml-jp-chart:"
let protected_marker_suffix = " -->"
let stats_marker_prefix = "{{ stats:"
let protected_stats_marker_prefix = "<!-- ocaml-jp-stats:"

let chart_index charts =
  List.map charts.charts ~f:(fun chart -> Chart.id chart, chart)
  |> Map.of_alist_exn (module String)
;;

let stats_index charts =
  List.map charts.stats ~f:(fun stats -> Stats.id stats, stats)
  |> Map.of_alist_exn (module String)
;;

let replace_markers charts ~content ~prefix ~suffix ~render =
  let chart_index =
    Option.value_map charts ~default:(Map.empty (module String)) ~f:chart_index
  in
  let find_chart id =
    match Map.find chart_index id, charts with
    | Some chart, _ -> chart
    | None, None -> failwith "chart marker found without a sibling YAML file"
    | None, Some _ -> failwithf "unknown chart id: %s" id ()
  in
  let prefix_length = String.length prefix in
  let suffix_length = String.length suffix in
  let content_length = String.length content in
  let rec loop ~position ~rendered ~used =
    match String.substr_index content ~pos:position ~pattern:prefix with
    | None ->
      let tail = String.sub content ~pos:position ~len:(content_length - position) in
      let unused = Set.diff (Map.key_set chart_index) used |> Set.to_list in
      if List.is_empty unused
      then String.concat (List.rev (tail :: rendered))
      else
        failwithf
          "charts are not placed in Markdown: %s"
          (String.concat unused ~sep:", ")
          ()
    | Some marker_start ->
      let id_start = marker_start + prefix_length in
      (match String.substr_index content ~pos:id_start ~pattern:suffix with
       | None -> failwith "unterminated chart marker"
       | Some marker_end ->
         let before = String.sub content ~pos:position ~len:(marker_start - position) in
         let id = String.sub content ~pos:id_start ~len:(marker_end - id_start) in
         let id = String.strip id in
         let rendered_chart = "\n\n" ^ render (find_chart id) ^ "\n\n" in
         loop
           ~position:(marker_end + suffix_length)
           ~rendered:(rendered_chart :: before :: rendered)
           ~used:(Set.add used id))
  in
  loop ~position:0 ~rendered:[] ~used:(Set.empty (module String))
;;

let replace_stats_markers charts ~content ~prefix ~suffix ~render =
  let stats_index =
    Option.value_map charts ~default:(Map.empty (module String)) ~f:stats_index
  in
  let find_stats id =
    match Map.find stats_index id, charts with
    | Some stats, _ -> stats
    | None, None -> failwith "stats marker found without a sibling YAML file"
    | None, Some _ -> failwithf "unknown stats id: %s" id ()
  in
  let prefix_length = String.length prefix in
  let suffix_length = String.length suffix in
  let content_length = String.length content in
  let rec loop ~position ~rendered ~used =
    match String.substr_index content ~pos:position ~pattern:prefix with
    | None ->
      let tail = String.sub content ~pos:position ~len:(content_length - position) in
      let unused = Set.diff (Map.key_set stats_index) used |> Set.to_list in
      if List.is_empty unused
      then String.concat (List.rev (tail :: rendered))
      else
        failwithf
          "stats are not placed in Markdown: %s"
          (String.concat unused ~sep:", ")
          ()
    | Some marker_start ->
      let id_start = marker_start + prefix_length in
      (match String.substr_index content ~pos:id_start ~pattern:suffix with
       | None -> failwith "unterminated stats marker"
       | Some marker_end ->
         let before = String.sub content ~pos:position ~len:(marker_start - position) in
         let id = String.sub content ~pos:id_start ~len:(marker_end - id_start) in
         let id = String.strip id in
         if Set.mem used id then failwithf "stats marker appears more than once: %s" id ();
         let rendered_stats = "\n\n" ^ render (find_stats id) ^ "\n\n" in
         loop
           ~position:(marker_end + suffix_length)
           ~rendered:(rendered_stats :: before :: rendered)
           ~used:(Set.add used id))
  in
  loop ~position:0 ~rendered:[] ~used:(Set.empty (module String))
;;

let protect_markers charts ~content =
  let content =
    replace_markers
      charts
      ~content
      ~prefix:marker_prefix
      ~suffix:marker_suffix
      ~render:(fun chart ->
        protected_marker_prefix ^ Chart.id chart ^ protected_marker_suffix)
  in
  replace_stats_markers
    charts
    ~content
    ~prefix:stats_marker_prefix
    ~suffix:marker_suffix
    ~render:(fun stats ->
      protected_stats_marker_prefix ^ Stats.id stats ^ protected_marker_suffix)
;;

let render_markers charts ~content ~render_chart ~render_stats =
  let content =
    replace_markers
      charts
      ~content
      ~prefix:protected_marker_prefix
      ~suffix:protected_marker_suffix
      ~render:render_chart
  in
  replace_stats_markers
    charts
    ~content
    ~prefix:protected_stats_marker_prefix
    ~suffix:protected_marker_suffix
    ~render:render_stats
;;
