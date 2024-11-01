{
  make_crate,
  ...
}:
make_crate {
  pname = "greet";
  version = "0.0.0";

  src = ./src;

  type = "dylib";
  system = "x86_64-linux";

  meta = {
    description = "Cargo alternative based on nix and nix flakes";
  };
}
