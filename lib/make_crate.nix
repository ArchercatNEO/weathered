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

  type ? "",
  src,

  buildDependencies ? [ ],
  runtimeDependencies ? [ ],
  transativeDependencies ? [ ],
  make_lock ? null,

  system ? builtins.currentSystem,
  meta,
  ...
}:
let
  mapExternsAndRpath = builtins.concatMap (dep: [
    "--extern ${dep.pname}=${dep}/lib/lib${dep.pname}.so"
  ]);
  linkFlags = mapExternsAndRpath runtimeDependencies;

  type' =
    if type != "" then
      type
    else if builtins.pathExists (src + ./main.rs) then
      "bin"
    else if builtins.pathExists (src + ./lib.rs) then
      "dylib"
    else
      throw "Crate type not given and no main/lib.rs file found";
in
derivation {
  inherit
    name
    pname
    edition
    system
    src
    ;

  type = type';

  builder = if type == "dylib" then ./make_crate_lib.sh else ./make_crate_bin.sh;

  outputs = [ "out" ];

  PATH = lib.makeBinPath [
    coreutils
    gcc
    rustc
  ];

  inherit linkFlags;

  inherit transativeDependencies make_lock;
}
