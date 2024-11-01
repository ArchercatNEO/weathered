{
  lib,
  bash,
  coreutils,
  gcc,
  rustc,
}:

{
  name ? "${pname}-${version}",
  pname,
  version,
  edition ? "2021",

  type,
  src,

  buildDependencies ? [ ],
  runtimeDependencies ? [ ],

  system ? builtins.currentSystem,
  meta,
}:
let
  mapExternsAndRpath = builtins.concatMap (dep: [
    "--extern ${dep.pname}=${dep}/lib/lib${dep.pname}.so"
  ]);
  linkFlags = mapExternsAndRpath runtimeDependencies;
in
derivation {
  inherit
    name
    pname
    edition
    system
    type
    src
    ;

  builder = if type == "dylib" then ./make_crate_lib.sh else ./make_crate_bin.sh;

  outputs = [ "out" ];

  PATH = lib.makeBinPath [
    coreutils
    gcc
    rustc
  ];

  inherit linkFlags;
}
