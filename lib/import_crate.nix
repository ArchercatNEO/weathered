{
  lib,
  fetchCrate,
  make_crate,
  runCommandLocal,
  ...
}:

# Type: Path -> Functor -> Derivation
crate:
let
  versions =
    builtins.readFile crate
    |> lib.splitString "\n"
    |> builtins.filter (json: json != "")
    |> builtins.map builtins.fromJSON;

  #version.name: the id of the crate
  #version.vers: the version of this crate
  #version.deps: list of deps
  #TODO: schema of deps
  #TODO: version.cksum
  #TODO: version.features
  #TODO: version.features2
  #TODO: version.yanked
  #TODO: version.rust_version

  versionToFunctor = sparce: rec {
    pname = sparce.name;
    version = sparce.vers;

    src = let 
      compressed = fetchCrate {
        pname = sparce.name;
        version = sparce.vers;
        hash = builtins.convertHash {
          hash = sparce.cksum;
          hashAlgo = "sha256";
          toHashFormat = "sri";
        };
        unpack = false;
        registryDl = "https://static.crates.io/crates";
      }; in runCommandLocal "unpacked-${pname}" {} ''
          unpackDir=$(mktemp -d)

          tar -xf ${compressed} -C "$unpackDir"
          mv "$unpackDir"/${pname}-${version} "$out"
          chmod 755 "$out"

          rm -r "$unpackDir"
      '';

    #TODO: expose build/runtime as <dep.value> strings in self
    #Can't expose as derivations before using callPackage
    __functor =
      self: args:
      let
        # this is inside because we depend on args
        deps = rec {
          buildDependencies =
            sparce.deps |> builtins.filter (dep: dep.kind == "dev") |> builtins.map (dep: args."${dep.name}"); # does not lock, just uses latest

          runtimeDependencies =
            sparce.deps
            |> builtins.filter (dep: dep.kind == "normal")
            |> builtins.map (dep: args."${dep.name}"); # does not lock, just uses latest

          transativeDependencies =
            let
              expandDeps = (dep: dep.transativeDependencies |> builtins.concatMap expandDeps |> lib.unique);
            in
            buildDependencies ++ runtimeDependencies |> builtins.concatMap expandDeps;
        };

        # we need to parse the Cargo.toml for everything after this
        cargo =
          let
            toml = lib.importTOML "${src}/Cargo.toml";
          in
          {
            edition = toml.package.edition;
            meta = { };
          };
      in
      make_crate (self // deps // cargo);
    __functionArgs =
      let
        required = dep: {
          name = dep.name;
          value = false;
        };
        oprional = dep: {
          name = dep.name;
          value = true;
        };

        deps = builtins.map required sparce.deps;
      in
      builtins.listToAttrs deps;
  };

  functors = builtins.map versionToFunctor versions;
  latest = lib.last functors;
  asVersions =
    let
      extractVersion = builtins.map (drv: {
        name = drv.version;
        value = drv;
      });
    in
    builtins.listToAttrs (extractVersion functors);
in
latest
// asVersions
// {
  __functor =
    self: args:
    (latest.__functor self args)
    // (builtins.mapAttrs (name: value: args.callPackage value { }) asVersions);
}
