{
  lib,
  import_crate,
}:
let
  inherit (builtins)
    map
    readDir
    ;

  inherit (lib.lists)
    concatMap
    flatten
    ;

  inherit (lib.attrsets)
    mergeAttrsList
    mapAttrsToList
    ;
in

# Type: Path -> Overlay
crates_io:
let
  # Type: Path -> String -> [Path]
  find =
    path: type:
    if type == "directory" then
      let
        ls = readDir path; # {path = type} -> [ { path = ...; type = ...;} ]
        paths = mapAttrsToList (key: value: {
          path = "${path}/${key}";
          type = value;
        }) ls;
      in
      concatMap (node: find node.path node.type) paths
    else if lib.elem (crates_io + "/README.md") path then
      [ ]
    else if lib.elem (crates_io + "/config.json") path then
      [ ]
    else if lib.elem (crates_io + "/.github/update-dl-url.yml") path then
      [ ]
    else
      [ path ];

  callPackage = lib.callPackageWith pkgs;

  # Type: [AttrsOf Derivation]
  crates =
    let
      # Type: [ [Path] ]
      matrix = mapAttrsToList find (readDir crates_io);
      # Type: [ Path ]
      flattened = flatten matrix;
      # Type: Path -> Attrset
      crateToAttrs =
        crate:
        let
          functor = import_crate crate;
        in
        {
          "${functor.pname}" = callPackage functor { };
        };

    in
    map crateToAttrs flattened;

  pkgs = mergeAttrsList crates;
in
pkgs
