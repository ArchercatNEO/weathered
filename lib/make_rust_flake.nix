{
  lib,
  rustenv,
  pkgs,
}:
let
  lib' = lib;
  rustenv' = rustenv;
in
{
  rustenv ? rustenv',
  crates,
  lib,
  ...
}:
lib'.eachSystem (
  system:
  let
    callPackage = (pkgs // { inherit rustenv; } // packages);
    packages = builtins.map (crate: callPackage crate { }) crates;
  in
  {
    devShells = { };

    inherit lib packages;
  }
)
