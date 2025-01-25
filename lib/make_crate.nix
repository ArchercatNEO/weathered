{
  lib,
  bash,
  coreutils,
  gcc,
  rustc,
}:
let
  inherit (lib) mapAttrsToList concatStringsSep makeBinPath;
in
{
  name ? "${pname}-${version}",
  pname,
  version,
  edition ? "2021",

  src,

  lib ? { },
  bin ? [ ],
  examples ? [ ],
  bench ? [ ],
  test ? [ ],

  buildDependencies ? { },
  runtimeDependencies ? { },

  rustFlags ? [ ],
  libFlags ? [ ],
  binFlags ? [ ],

  system ? builtins.currentSystem,
  meta,
  ...
}:
let
  linkFlags =
    runtimeDependencies
    |> (val: builtins.trace name val)
    |> mapAttrsToList (name: value: "--extern ${name}=${value}/lib/lib${value.pname}.so")
    |> (val: builtins.trace val val);

  rustcFlags =
    rustFlags
    ++ linkFlags
    ++ [
      "--edition ${edition}"
      "-C embed-bitcode=no"
      "-C debuginfo=2"
      "-C prefer-dynamic"
    ];

in
derivation {
  inherit
    name
    pname
    system
    src
    ;

  builder = "${bash}/bin/bash";
  args = [ ./make_crate.sh ];

  outputs = [ "out" ];

  LIB =
    if lib ? path then
      [
        lib.path
        "--crate-name ${lib.name or pname}"
        "--crate-type dylib"
      ]
      ++ libFlags
      ++ rustcFlags
    else
      "";

  BIN =
    let
      binToArgs =
        bin:
        (
          [
            bin.path
            "--crate-name ${bin.name or pname}"
            "--crate-type bin"
            "-C rpath"
          ]
          ++ binFlags
          ++ rustcFlags
        )
        |> concatStringsSep " "
        |> (str: "${str}");
    in
    builtins.map binToArgs bin |> concatStringsSep ":";

  #Do these build anything?
  EXAMPLE = [ ];
  TEST = [ ];
  BENCH = [ ];

  PATH = makeBinPath [
    coreutils
    gcc
    rustc
  ];
}
