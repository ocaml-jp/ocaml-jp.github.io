{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    opam-nix.url = "github:tweag/opam-nix";
  };
  outputs = { flake-utils, nixpkgs, opam-nix, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        on   = opam-nix.lib.${system};

        src = ./.;
        localNames = with builtins;
          let
            files      = attrNames (readDir src);
            opam_files = map (match "(.*)\.opam$") files;
            non_nulls  = filter (f: !isNull f);
          in 
            map (f: elemAt f 0) (non_nulls opam_files);

        localPackagesQuery = with builtins; 
          listToAttrs (map (p: { name = p; value = "*"; }) localNames);

        devPackagesQuery = {
          ocaml-base-compiler = "*";
          ocaml-lsp-server = "*";
          ocamlformat = "*";
        };

        query = devPackagesQuery // localPackagesQuery;

        localPackages =
          on.buildOpamProject'
          {
            inherit pkgs;
            resolveArgs = { with-test = false; with-doc = false; };
            pinDepends = true;
          }
          src
          query;

        devPackages = builtins.attrValues
          (pkgs.lib.getAttrs (builtins.attrNames devPackagesQuery) localPackages);
      in
      {
        legacyPackages = pkgs;

        devShells.default =
          pkgs.mkShell {
            inputsFrom  = builtins.map (p: localPackages.${p}) localNames;
            buildInputs = with pkgs; [
              nil nixpkgs-fmt 
            ] ++ devPackages;
          };
      });
}
