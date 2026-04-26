open Core
open Yocaml

let into = Path.rel [ "www" ]
let assets = Path.rel [ "assets" ]
let copy_file_to_www f = Action.copy_file ~into Path.(assets / f)

let create_css =
  let css = Path.(assets / "css") in
  Path.[ css / "style.css" ]
  |> Pipeline.pipe_files ~separator:"\n"
  |> Action.Static.write_file Path.(into / "style.css")
;;

let track_binary =
  Sys_unix.executable_name |> Yocaml.Path.from_string |> Pipeline.track_file
;;

let create_index =
  let source = Path.rel [ "contents"; "index_main.html" ] in
  Action.Static.write_file
    Path.(move ~into @@ rel [ "index.html" ])
    Task.(
      let+ () = track_binary
      and+ template =
        Yocaml_jingoo.read_template Path.(assets / "templates" / "layout.html")
      and+ metadata, content =
        Yocaml_yaml.Pipeline.read_file_with_metadata (module Archetype.Page) source
      in
      template (module Archetype.Page) ~metadata content)
;;

let write_markdown source ~into =
  let page_path = source |> Path.move ~into |> Path.change_extension "html" in
  let pipeline =
    let open Task in
    let+ () = track_binary
    and+ apply_templates =
      Yocaml_jingoo.read_templates
        Path.[ assets / "templates" / "page.html"; assets / "templates" / "layout.html" ]
    and+ metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata (module Archetype.Page) source
    in
    Yocaml_markdown.from_string_to_html content
    |> apply_templates (module Archetype.Page) ~metadata
  in
  Action.Static.write_file page_path pipeline
;;

let with_ext exts file = List.exists exts ~f:(fun ext -> Path.has_extension ext file)
let is_markdown = with_ext [ "md" ]

let is_not_index file =
  match Path.basename file with
  | Some "index.md" -> false
  | _ -> true
;;

let create_events =
  let where file = is_markdown file && is_not_index file in
  Batch.iter_files
    ~where
    (Path.rel [ "contents"; "events" ])
    (write_markdown ~into:(Path.rel [ "www"; "events" ]))
;;

let compute_event_link source =
  let into = Path.abs [ "events" ] in
  source |> Path.move ~into |> Path.change_extension "html"
;;

module Event = struct
  let entity_name = "Event"

  type t =
    { title : string
    ; date : Archetype.Datetime.t
    ; upcoming : bool
    }

  let neutral =
    Data.Validation.fail_with ~given:"null" "Cannot be null"
    |> Result.map_error ~f:(fun error ->
      Required.Validation_error { entity = entity_name; error })
  ;;

  let validate =
    let open Data.Validation in
    record (fun fields ->
      let+ title = required fields "title" string
      and+ date = required fields "date" Archetype.Datetime.validate
      and+ upcoming = optional_or fields ~default:false "upcoming" bool in
      { title; date; upcoming })
  ;;

  let normalize { title; date; upcoming } =
    Data.
      [ "title", string title
      ; "date", Archetype.Datetime.normalize date
      ; "upcoming", bool upcoming
      ]
  ;;
end

module Events = struct
  type t =
    { page : Archetype.Page.t
    ; events : (Path.t * Event.t) list
    }

  let with_page ~events ~page = { page; events }

  let sort_by_date events =
    List.sort
      events
      ~compare:
        (Comparable.lift
           (Comparable.reverse Archetype.Datetime.compare)
           ~f:(fun (_, (e : Event.t)) -> e.date))
  ;;

  let normalize_event (path, event) =
    Data.record (("url", Data.string @@ Path.to_string path) :: Event.normalize event)
  ;;

  let normalize { page; events } =
    let upcoming, past =
      List.partition_tf events ~f:(fun (_, (e : Event.t)) -> e.upcoming)
    in
    Archetype.Page.normalize page
    @ Data.
        [ "upcoming_events", list_of normalize_event upcoming
        ; "past_events", list_of normalize_event past
        ; "has_upcoming_events", bool (not (List.is_empty upcoming))
        ; "has_past_events", bool (not (List.is_empty past))
        ]
  ;;
end

let fetch_events =
  let where file = is_markdown file && is_not_index file in
  let open Task in
  Pipeline.fetch
    ~only:`Files
    ~where
    ~on:`Source
    (fun file ->
       let open Eff in
       let url = compute_event_link file in
       let+ metadata, _content =
         Eff.read_file_with_metadata (module Yocaml_yaml) (module Event) ~on:`Source file
       in
       url, metadata)
    (Path.rel [ "contents"; "events" ])
  >>| Events.sort_by_date
;;

let create_events_index =
  let source = Path.rel [ "contents"; "events"; "index.md" ] in
  let target_dir = Path.rel [ "www"; "events" ] in
  let index_path = source |> Path.move ~into:target_dir |> Path.change_extension "html" in
  let pipeline =
    let open Task in
    let+ () = track_binary
    and+ apply_templates =
      Yocaml_jingoo.read_templates
        Path.
          [ assets / "templates" / "events_index.html"
          ; assets / "templates" / "page.html"
          ; assets / "templates" / "layout.html"
          ]
    and+ events = fetch_events
    and+ metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata (module Archetype.Page) source
    in
    let metadata = Events.with_page ~page:metadata ~events in
    Yocaml_markdown.from_string_to_html content
    |> apply_templates (module Events) ~metadata
  in
  Action.Static.write_file index_path pipeline
;;

let process () =
  let open Eff in
  let cache = Path.(into / ".cache") in
  Action.restore_cache cache
  >>= copy_file_to_www "favicon.ico"
  >>= copy_file_to_www "favicon-16x16.ico"
  >>= copy_file_to_www "favicon.svg"
  >>= copy_file_to_www "apple-touch-icon.png"
  >>= create_css
  >>= create_index
  >>= create_events
  >>= create_events_index
  >>= Action.store_cache cache
;;

let () =
  let level = `Debug in
  let target = into in
  let port = 8080 in
  match Sys.get_argv () with
  | [| _ |] | [| _; "build" |] -> Yocaml_unix.run ~level process
  | [| _; "serve" |] -> Yocaml_unix.serve ~level ~target ~port process
  | _ ->
    let open Printf in
    eprintf "Usage: %s [build|serve]\n" (Sys.get_argv ()).(0);
    eprintf "  build  Generate static site (default)\n";
    eprintf "  serve  Start development server on port 8000\n";
    exit 1
;;
