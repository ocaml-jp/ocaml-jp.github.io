{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    { flake-utils, nixpkgs, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        dune = pkgs.dune_3.overrideAttrs (_: rec {
          version = "3.22.0";
          src = pkgs.fetchurl {
            url = "https://github.com/ocaml/dune/releases/download/${version}/dune-${version}.tbz";
            hash = "sha256-y4FrLmcspsbqaAEz8BKHvZWljKYRy0dqz/Z7itus9yI=";
          };
        });
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            dune
            pkg-config
            nil
            nixpkgs-fmt
          ];

          shellHook = ''
            if [ -f dune-project ]; then
              eval "$(dune tool env 2>/dev/null)" || true
            fi
          '';
        };
      }
    );
}
