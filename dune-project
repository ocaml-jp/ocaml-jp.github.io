(lang dune 3.20)

(name ocaml-jp)

(generate_opam_files true)

(package
  (name ocaml-jp)
  (version 0.1.0)
  (synopsis "OCaml.jp website using YOCaml")
  (description "Static site generator for OCaml.jp using YOCaml framework")
  (maintainers "OCaml.jp maintainers")
  (authors "OCaml.jp community")
  (license MIT)
  (depends
    ocaml
    dune
    yocaml
    yocaml_unix
    yocaml_omd
    yocaml_jingoo
    yocaml_yaml
    yocaml_markdown
    yocaml_syndication
    (ocamlformat
      (and
        (= 0.27.0)
        :with-dev-setup))
    ))
