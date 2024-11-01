{
  make_crate,
  greet,
  ...
}:
make_crate {
  pname = "weathered";
  version = "0.0.0";

  src = ./src;
  type = "bin";

  runtimeDependencies = [
    greet
  ];

  system = "x86_64-linux";

  meta = {
    description = "Cargo alternative based on nix and nix flakes";
  };
}
