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
    system = "x86_64-linux";

    pname = sparce.name;
    version = sparce.vers;

    src =
      let
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
        };
      in
      runCommandLocal "unpacked-${pname}" { } ''
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
        deps =
          let
            cratesToDrvs =
              filter: crates:
              crates
              |> builtins.filter filter
              |> builtins.map (crate: {
                inherit (crate) name;
                value = if crate ? package then args."${crate.package}" else args."${crate.name}";
              })
              |> builtins.listToAttrs;
          in
          {
            buildDependencies = cratesToDrvs (dep: dep.kind == "dev") sparce.deps;
            runtimeDependencies = cratesToDrvs (dep: dep.kind == "normal") sparce.deps;
          };

        # we need to parse the Cargo.toml for everything after this
        manifest =
          let
            cargo = lib.importTOML "${src}/Cargo.toml";
          in
          {
            edition = cargo.package.edition or "2015";
            meta = { };
          };
      in
      make_crate (self // deps // manifest);
    __functionArgs =
      let
        required = dep: {
          name = if dep ? package then dep.package else dep.name;
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
