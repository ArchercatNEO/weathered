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
    mapAttrs'
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
    else if lib.strings.hasInfix "README.md" path then
      [ ]
    else if lib.strings.hasInfix "config.json" path then
      [ ]
    else if lib.strings.hasInfix "update-dl-url.yml" path then
      [ ]
    else
      [ path ];

  callPackage = lib.callPackageWith pkgs;

  # Type: [AttrsOf Derivation]
  crates =
    let
      abs = mapAttrs' (name: value: {
        name = builtins.unsafeDiscardStringContext "${crates_io}/${name}";
        inherit value;
      }) (readDir crates_io);
      # Type: [ [Path] ]
      matrix = mapAttrsToList find abs;
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
