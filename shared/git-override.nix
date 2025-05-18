{
  lib,
  callPackage,
  importJSON ? lib.trivial.importJSON,
  nyx,
  fetchFromGitHub,
  fetchFromGitLab,
  fetchRevFromGitHub,
  fetchRevFromGitLab,
  fetchCargoVendor,
}:
config:
let
  arrange =
    {
      nyxKey,
      versionNyxPath,
      prev,
      fetcher,
      fetcherData,
      ref ? "main",
      version ? null,
      newInputs ? null,
      postOverride ? null,
      preOverride ? null,
      withUpdateScript ? true,
      withLastModified ? false,
      withLastModifiedDate ? false,
      withBump ? false,
      withCargoDeps ? null,
      withExtraUpdateCommands ? "",
      extraPassthru ? { },
      buildCargoDepsWithPatches ? null,
    }:
    let
      versionLocalPath = "${nyx}/${versionNyxPath}";
      current = importJSON versionLocalPath;

      fetchers = { inherit fetchFromGitHub fetchFromGitLab; };
      fullFetcherData = fetcherData // {
        inherit (current) rev hash;
      };
      fetchLatestRev =
        if fetcher == "fetchFromGitHub" then
          fetchRevFromGitHub
        else if fetcher == "fetchFromGitLab" then
          fetchRevFromGitLab
        else
          throw "Unrecognized fetcher ${builtins.toString fetcher}";

      main =
        prevAttrs:
        let
          src = fetchers.${fetcher} fullFetcherData;

          hasCargo = prevAttrs ? cargoDeps;

          updateScript = callPackage ./git-update.nix {
            inherit (prevAttrs) pname;
            inherit
              nyxKey
              hasCargo
              withLastModified
              withLastModifiedDate
              withBump
              ;
            hasSubmodules = fetcherData.fetchSubmodules or false;
            versionPath = versionNyxPath;
            fetchLatestRev = fetchLatestRev ref fullFetcherData;
            gitUrl = src.gitRepoUrl;
            withExtraCommands = withExtraUpdateCommands;
          };

          common = {
            inherit src;
            version = if version == null then current.version else version;
            passthru =
              (prevAttrs.passthru or { })
              // {
                updateScript = if withUpdateScript then updateScript else null;
              }
              // extraPassthru;
          };

          whenCargo = lib.attrsets.optionalAttrs hasCargo {
            cargoDeps =
              if withCargoDeps == null then
                fetchCargoVendor {
                  inherit src;
                  inherit (prevAttrs.cargoDeps) name;
                  sourceRoot = prevAttrs.cargoDeps.sourceRoot or null;
                  patches =
                    if buildCargoDepsWithPatches != null then
                      buildCargoDepsWithPatches final
                    else
                      prevAttrs.cargoDeps.patches or [ ];
                  preUnpack = prevAttrs.cargoDeps.preUnpack or null;
                  unpackPhase = prevAttrs.cargoDeps.unpackPhase or null;
                  postUnpack = prevAttrs.cargoDeps.postUnpack or null;
                  hash = current.cargoHash;
                }
              else
                withCargoDeps;
          };
        in
        common // whenCargo;

      optionalPreOverride = lib.lists.optional (preOverride != null) preOverride;

      optionalPostOverride = lib.lists.optional (postOverride != null) postOverride;

      final = lib.lists.foldl (accu: accu.overrideAttrs) (
        if newInputs == null then prev else prev.override newInputs
      ) (optionalPreOverride ++ [ main ] ++ optionalPostOverride);
    in
    {
      inherit final current;
    };

  env = if builtins.isFunction config then config current else config;

  arranged = arrange env;
  inherit (arranged) current final;
in
final
