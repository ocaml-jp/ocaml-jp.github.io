open Yocaml

let into = Path.rel [ "www" ]
let assets = Path.rel [ "assets" ]
let copy_favicon = Action.copy_file ~into Path.(assets / "favicon.ico")

let create_css =
  let css = Path.(assets / "css") in
  Path.[ css / "style.css" ]
  |> Pipeline.pipe_files ~separator:"\n"
  |> Action.Static.write_file Path.(into / "style.css")
;;

let track_binary = Sys.executable_name |> Yocaml.Path.from_string |> Pipeline.track_file

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

let with_ext exts file = List.exists (fun ext -> Path.has_extension ext file) exts
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

let fetch_events =
  let where file = is_markdown file && is_not_index file in
  Archetype.Articles.fetch
    ~where
    ~compute_link:compute_event_link
    (module Yocaml_yaml)
    (Path.rel [ "contents"; "events" ])
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
    and+ articles = fetch_events
    and+ metadata, content =
      Yocaml_yaml.Pipeline.read_file_with_metadata (module Archetype.Page) source
    in
    let metadata = Archetype.Articles.with_page ~page:metadata ~articles in
    Yocaml_markdown.from_string_to_html content
    |> apply_templates (module Archetype.Articles) ~metadata
  in
  Action.Static.write_file index_path pipeline
;;

let process () =
  let open Eff in
  let cache = Path.(into / ".cache") in
  Action.restore_cache cache
  >>= copy_favicon
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
  match Sys.argv with
  | [| _ |] | [| _; "build" |] -> Yocaml_unix.run ~level process
  | [| _; "serve" |] -> Yocaml_unix.serve ~level ~target ~port process
  | _ ->
    let open Printf in
    eprintf "Usage: %s [build|serve]\n" Sys.argv.(0);
    eprintf "  build  Generate static site (default)\n";
    eprintf "  serve  Start development server on port 8000\n";
    exit 1
;;
