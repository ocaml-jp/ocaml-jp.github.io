open! Core
open Yocaml

let max_series = 6
let percentage ~responses count = Float.of_int count /. Float.of_int responses *. 100.0
let percentage_css ~responses count = sprintf "%.4f%%" (percentage ~responses count)

let percentage_label ~responses count =
  if Int.equal (count * 100 mod responses) 0
  then sprintf "%d%%" (count * 100 / responses)
  else sprintf "%.1f%%" (percentage ~responses count)
;;

let relative_css ~max_count count =
  if Int.equal max_count 0 then "0%" else percentage_css ~responses:max_count count
;;

let series_index index = (index mod max_series) + 1

module Item = struct
  type t =
    { label : string
    ; count : int
    }

  let validate =
    let open Data.Validation in
    record (fun fields ->
      let+ label = required fields "label" string
      and+ count = required fields "count" (int & positive) in
      { label; count })
  ;;
end

module Series = struct
  type t = { label : string }

  let validate =
    let open Data.Validation in
    record (fun fields ->
      let+ label = required fields "label" string in
      { label })
  ;;
end

module Group = struct
  type t =
    { label : string
    ; values : int list
    }

  let validate =
    let open Data.Validation in
    record (fun fields ->
      let+ label = required fields "label" string
      and+ values = required fields "values" (list_of (int & positive) & non_empty) in
      { label; values })
  ;;
end

module Kind = struct
  type t =
    | Pie
    | Bars
    | Columns
    | Grouped_bars

  let all = [ Pie; Bars; Columns; Grouped_bars ]

  let to_string = function
    | Pie -> "pie"
    | Bars -> "bars"
    | Columns -> "columns"
    | Grouped_bars -> "grouped-bars"
  ;;

  let of_string given = List.find all ~f:(fun kind -> String.equal (to_string kind) given)

  let validate =
    let message =
      sprintf "expected one of: %s" (List.map all ~f:to_string |> String.concat ~sep:", ")
    in
    let open Data.Validation in
    string & String.where_opt ~message:(Fn.const message) of_string
  ;;
end

type t =
  { id : string
  ; title : string
  ; responses : int
  ; multiple : bool
  ; kind : Kind.t
  ; items : Item.t list
  ; series : Series.t list
  ; groups : Group.t list
  }

let id chart = chart.id
let fail chart message = Data.Validation.fail_with ~given:chart.title message

let all_counts_fit ~responses items =
  List.for_all items ~f:(fun ({ count; _ } : Item.t) -> count <= responses)
;;

let validate_multiple chart =
  match chart.multiple, chart.kind with
  | false, _ | true, Kind.Bars -> Ok chart
  | true, (Kind.Pie | Kind.Columns | Kind.Grouped_bars) ->
    fail chart "only bars charts may use multiple: true"
;;

let validate_items chart =
  if List.is_empty chart.items
  then fail chart "items must not be empty"
  else if not (List.is_empty chart.series && List.is_empty chart.groups)
  then fail chart "series and groups are only valid for grouped-bars charts"
  else if not (all_counts_fit ~responses:chart.responses chart.items)
  then fail chart "an item count exceeds the number of responses"
  else if chart.multiple
  then Ok chart
  else (
    let total = List.sum (module Int) chart.items ~f:(fun item -> item.count) in
    if Int.equal total chart.responses
    then Ok chart
    else fail chart "item counts must add up to the number of responses")
;;

let validate_group chart ({ values; _ } : Group.t) =
  if not (Int.equal (List.length values) (List.length chart.series))
  then fail chart "each group must contain one value for every series"
  else if List.exists values ~f:(fun value -> value > chart.responses)
  then fail chart "a grouped value exceeds the number of responses"
  else (
    let total = List.sum (module Int) values ~f:Fn.id in
    if Int.equal total chart.responses
    then Ok ()
    else fail chart "each group's values must add up to the number of responses")
;;

let validate_groups chart =
  if List.is_empty chart.series
  then fail chart "series must not be empty"
  else if List.length chart.series > max_series
  then fail chart (sprintf "grouped-bars charts support at most %d series" max_series)
  else if List.is_empty chart.groups
  then fail chart "groups must not be empty"
  else if not (List.is_empty chart.items)
  then fail chart "items are not valid for grouped-bars charts"
  else
    List.map chart.groups ~f:(validate_group chart)
    |> Result.all_unit
    |> Result.map ~f:(fun () -> chart)
;;

let validate_shape chart =
  match chart.kind with
  | Kind.Grouped_bars -> validate_groups chart
  | Kind.Pie | Kind.Bars | Kind.Columns -> validate_items chart
;;

let validate data =
  let open Data.Validation in
  record
    (fun fields ->
       let+ id = required fields "id" (Slug.validate & String.not_empty)
       and+ title = required fields "title" string
       and+ responses = required fields "responses" (int & Int.gt 0)
       and+ multiple = optional_or fields "multiple" ~default:false bool
       and+ kind = required fields "kind" Kind.validate
       and+ items = optional_or fields "items" ~default:[] (list_of Item.validate)
       and+ series = optional_or fields "series" ~default:[] (list_of Series.validate)
       and+ groups = optional_or fields "groups" ~default:[] (list_of Group.validate) in
       { id; title; responses; multiple; kind; items; series; groups })
    data
  |> Result.bind ~f:validate_multiple
  |> Result.bind ~f:validate_shape
;;

let max_count chart =
  let counts =
    match chart.kind with
    | Kind.Grouped_bars -> List.concat_map chart.groups ~f:(fun group -> group.values)
    | Kind.Pie | Kind.Bars | Kind.Columns ->
      List.map chart.items ~f:(fun item -> item.count)
  in
  List.max_elt counts ~compare:Int.compare |> Option.value ~default:0
;;

let normalize_item chart ~max_count index ({ label; count } : Item.t) =
  Data.record
    [ "label", Data.string label
    ; "count", Data.int count
    ; "percentage_label", Data.string (percentage_label ~responses:chart.responses count)
    ; "percentage_css", Data.string (percentage_css ~responses:chart.responses count)
    ; "relative_css", Data.string (relative_css ~max_count count)
    ; "series_index", Data.int (series_index index)
    ]
;;

let normalize_series index ({ label } : Series.t) =
  Data.record
    [ "label", Data.string label; "series_index", Data.int (series_index index) ]
;;

let normalize_group ~max_count ({ label; values } : Group.t) =
  let values =
    List.mapi values ~f:(fun index count ->
      Data.record
        [ "count", Data.int count
        ; "relative_css", Data.string (relative_css ~max_count count)
        ; "series_index", Data.int (series_index index)
        ])
  in
  Data.record [ "label", Data.string label; "values", Data.list values ]
;;

let pie_style chart =
  List.folding_map chart.items ~init:0 ~f:(fun start_count item ->
    let end_count = start_count + item.count in
    end_count, (start_count, end_count))
  |> List.mapi ~f:(fun index (start_count, end_count) ->
    sprintf
      "var(--chart-series-%d) %s %s"
      (series_index index)
      (percentage_css ~responses:chart.responses start_count)
      (percentage_css ~responses:chart.responses end_count))
  |> String.concat ~sep:", "
  |> sprintf "--chart-pie: conic-gradient(%s)"
;;

let aria_label chart =
  let values =
    match chart.kind with
    | Kind.Grouped_bars ->
      List.map chart.groups ~f:(fun group ->
        let values =
          List.map2_exn chart.series group.values ~f:(fun series count ->
            sprintf "%s %d" series.label count)
          |> String.concat ~sep:"、"
        in
        sprintf "%s：%s" group.label values)
    | Kind.Pie | Kind.Bars | Kind.Columns ->
      List.map chart.items ~f:(fun item -> sprintf "%s %d" item.label item.count)
  in
  chart.title ^ "。" ^ String.concat values ~sep:"。"
;;

let normalize chart =
  let max_count = max_count chart in
  let pie_style =
    match chart.kind with
    | Kind.Pie -> pie_style chart
    | Kind.Bars | Kind.Columns | Kind.Grouped_bars -> ""
  in
  Data.
    [ "id", string chart.id
    ; "title", string chart.title
    ; ( "response_context"
      , string
          (if chart.multiple
           then sprintf "複数回答・%d件" chart.responses
           else sprintf "%d件の回答" chart.responses) )
    ; "kind", string (Kind.to_string chart.kind)
    ; "items", list (List.mapi chart.items ~f:(normalize_item chart ~max_count))
    ; "series", list (List.mapi chart.series ~f:normalize_series)
    ; "groups", list (List.map chart.groups ~f:(normalize_group ~max_count))
    ; "pie_style", string pie_style
    ; "aria_label", string (aria_label chart)
    ]
;;
