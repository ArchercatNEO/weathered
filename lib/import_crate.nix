{
  lib,
  fetchCrate,
  make_crate,
  ...
}:

# Type: Path -> Functor -> Derivation
crate:
let
  versions =
    let
      readAndTrace = builtins.readFile crate;
      crates = lib.trim readAndTrace;
      splitNewline = lib.splitString "\n";
      fromJson = builtins.map builtins.fromJSON;
    in
    fromJson (splitNewline crates);
  #version.name: the id of the crate
  #version.vers: the version of this crate
  #version.deps: list of deps
  #TODO: schema of deps
  #TODO: version.cksum
  #TODO: version.features
  #TODO: version.features2
  #TODO: version.yanked
  #TODO: version.rust_version

  versionToFunctor = version': {
    pname = version'.name;
    version = version'.vers;

    src = fetchCrate {
      pname = version'.name;
      version = version'.vers;
      registryDl = "https://static.crates.io/crates";
      #extension = ".gz";
    };

    #TODO: expose build/runtime as <dep.value> strings in self
    #Can't expose as derivations before using callPackage
    __functor =
      self: args:
      make_crate (
        self
        // {
          buildDependencies = builtins.filter (dep: dep.kind == "dev") version'.deps; # there's more in this
          runtimeDependencies =
            let
              deps = builtins.filter (dep: dep.kind == "normal") version'.deps;
              drvs = builtins.map (dep: args."${dep.name}"."${dep.version}") deps;
            in
            drvs;
        }
      );
    __functionArgs =
      let
        required = dep: {
          name = dep.name;
          value = true;
        };
        oprional = dep: {
          name = dep.name;
          value = false;
        };

        deps = builtins.map required version'.deps;
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
