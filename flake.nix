{
  description = "A cargo alternative based on nix and nix flakes";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils?ref=main";

    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    fenix = {
      url = "github:nix-community/fenix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    crates_io = {
      url = "github:rust-lang/crates.io-index";
      flake = false;
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      treefmt,
      fenix,
      crates_io,
    }:
    let
      systems = [ "x86_64-linux" ];
    in
    flake-utils.lib.eachSystem systems (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            fenix.overlays.default
          ];
        };

        toolchain = pkgs.fenix.complete.withComponents [
          "rustc"
          "rust-std"
          "rust-src"
          "rustfmt"
        ];

        lib = {
          make_crate = pkgs.callPackage ./lib/make_crate.nix {
            rustc = toolchain;
          };
          import_crate = pkgs.callPackage ./lib/import_crate.nix {
            inherit (lib) make_crate;
          };
          import_crates_io = pkgs.callPackage ./lib/import_crates_io.nix {
            inherit (lib) import_crate;
          };
        };

        crates = lib.import_crates_io crates_io;
      in
      {
        devShells.default = pkgs.mkShell {
          name = "weathered-shell";

          packages = [
            toolchain
            pkgs.llvmPackages.bintools
          ];
        };

        formatter = (treefmt.lib.evalModule pkgs ./treefmt.nix).config.build.wrapper;

        inherit lib;
        packages.trunk = crates.trunk;
      }
    );
}
