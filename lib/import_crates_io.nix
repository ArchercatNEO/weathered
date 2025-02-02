{
  lib,
  import_crate,
}:
let
  inherit (builtins)
    readDir
    ;

  inherit (lib.attrsets)
    concatMapAttrs
    ;
in

# Type: Path -> Overlay
crates_io:
let
  # Type: Path -> String -> (AttrsOf Derivation)
  foldCrates =
    path: type:
    if type == "directory" then
      readDir path |> concatMapAttrs (name: value: foldCrates "${path}/${name}" value)
    else if lib.strings.hasInfix "README.md" path then
      { }
    else if lib.strings.hasInfix "config.json" path then
      { }
    else if lib.strings.hasInfix "update-dl-url.yml" path then
      { }
    else
      let
        functor = import_crate path;
      in
      {
        "${functor.pname}" = callPackage functor { };
      };

  callPackage = lib.callPackageWith pkgs;

  # Type: [AttrsOf Derivation]
  pkgs = foldCrates crates_io "directory";

in
pkgs
