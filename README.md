# OCaml.jp Website

## Project Structure

```
├── flake.nix
├── dune-project
├── src/            # site generator
│   ├── main.ml
│   └── dune
├── contents/       # page contents (markdown)
│   └── pages/
├── assets/
│   ├── templates/  # html templates
│   ├── css/
│   └── favicon.ico
└── www/
    ├── refman/     # old site contents (translated OCaml 3.12 reference)
    ├── temporary/  # old site contents (attachements about ocaml meeting in Japan)
    └── ...         # genereted contents (git ignored)
```

## Development

### Setup on nix and direnv

```bash
direnv allow
```

### Build

```bash
dune build
```

### Generate

```bash
dune exec ocaml-jp-site
```
