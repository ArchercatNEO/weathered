{ callPackage, ... }:
{ }:
{
  channel = "stable";
  date = "2024-10-28";
  target = "x86_64-unknown-linux-gnu";

  rustc = { };
  rust-std = { };

  rustsrc = { };
  rust-docs = { };
  clippy = { };
  rustfmt = { };
  rust-analyzer = { };

  make_crate = callPackage ./make_crate.nix { };
}
