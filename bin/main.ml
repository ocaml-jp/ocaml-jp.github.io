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

let process () =
  let open Eff in
  let cache = Path.(into / ".cache") in
  Action.restore_cache cache
  >>= copy_favicon
  >>= create_css
  >>= create_index
  >>= Action.store_cache cache
;;

let _serve =
  let port = 8000 in
  Yocaml_unix.serve ~level:`Info ~target:into ~port
;;

let () = Yocaml_unix.run process
