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

  #version.cksum: base16 sha256 of uncompressed crate
  #version.features: Dictionary<string, List<string>> key = name of feature, value = feature dependencies
  #TODO: version.features2
  #TODO: version.yanked
  #TODO: version.rust_version

  #version.deps: list of deps
  #version.deps[].name: name of dep
  #version.deps[].req: range of "req"uired versions
  #version.deps[].features: features flags to be compiled with
  #version.deps[].optional: whether the dependency is optional
  #version.deps[].default_features: whether the "default" feature is enabled
  #version.deps[].target: #TODO
  #version.deps[].kind: one of: normal (runtime), dev (shell), build

  versionToFunctor =
    sparce:
    let
      #! parse sparce (crate.io index) json

      # evaluate features
      # evaluate dependencies
      # override dependency features
      # create attrset of default function args
      # create attrset of function args

      featuresAndDeps =
        args:
        let 
          #feature types:
          # default = []; features enabled by default. see feature with deps
          # webp = []; regular feature,
          #  if enabled add '--cfg "feature=webp"'
          # serde = ["webp"]; feature with deps,
          #  if enabled recursively add --cfg for this and all dependents
          # git = ["dep:git"]; optional dependency,
          #  if enabled add '--cfg "feature=git"' and --extern git=${git}
          # serde = ["axium/serde"]; enable feature for dependency
          #  if enabled add --cfg serde, add --extern axium and override axium with serde feature
          # serde = ["axium?/serde"]; optionally enable feature for dependency
          #  if enabled add --cfg serde and if axium was already enabled override it with serde feature
          featureExpansion = feature: {
            flags = [];
          };
        in
        {

        };

      depsToDeps =
        crates:
        let
          extractFromCrates =
            {
              name,
              package ? "",
              req,
              features,
              optional,
              default_features,
              target,
              kind,
            }:
            let
              pkg = if package != "" then crates."${package}" else crates."${name}";
            in
            pkg.override (features // { inherit default_features; });
          cratesToDrvs =
            filter:
            sparce.deps
            |> builtins.filter filter
            |> builtins.map (crate: {
              inherit (crate) name;
              value = extractFromCrates crate;
            })
            |> builtins.listToAttrs
            |> (val: builtins.trace sparce.name val)
            |> (val: builtins.trace val val);

          attrs = {
            runtimeDependencies = cratesToDrvs (crate: crate.kind == "normal" && !crate.optional);
            #devDependencies = cratesToDrvs (crate: crate.kind == "dev" && !crate.optional);
            #buildDependencies = cratesToDrvs (crate: crate.kind == "build" && !crate.optional);
          };
        in
        attrs;

            
      features =
        let
          expandFeature = builtins.mapAttrs (
            name: value:
            value
            |> builtins.map (
              feat:
              if lib.strings.hasInfix ":" then
                { "${name}" = null; } # disable optional dependency by default
              else if lib.strings.hasInfix "/" then
                { } # override dependency feature
              else
                { }
            )
          );
        in
        args: { };
      # if feature in args.features
      # (self // (expand feature)

      #! parse Cargo.toml

      # evaluate edition
      # evaluate target paths
      # evaluate workspaces
      # evaluate metadata
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
        runCommandLocal "unpacked-${sparce.name}" { } ''
          unpackDir=$(mktemp -d)

          tar -xf ${compressed} -C "$unpackDir"
          mv "$unpackDir"/${sparce.name}-${sparce.vers} "$out"
          chmod 755 "$out"

          rm -r "$unpackDir"
        '';
      

      manifest =
        let
          cargo = lib.importTOML "${src}/Cargo.toml";
        in
        {
          edition = cargo.package.edition or "2015";
          
          lib = cargo.lib or {};
          bin = cargo.bin or [];
          examples = cargo.examples or [];
          bench = cargo.bench or [];
          test = cargo.test or [];
          
          meta = {
            inherit (cargo.package)
              authors
              description
              ;
          };
        };

    in
     {
      system = "x86_64-linux";

      pname = sparce.name;
      version = sparce.vers;

      inherit src;

      #TODO: expose build/runtime as <dep.value> strings in self
      #Can't expose as derivations before using callPackage
      __functor =
        self: args:
        let
          # we need to parse the Cargo.toml for everything after this
          
        in
        make_crate (self // (depsToDeps args) // manifest);
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
