{ lib
, callPackage
, importJSON ? lib.trivial.importJSON
, nyx
, fetchFromGitHub
, fetchFromGitLab
, fetchRevFromGitHub
, fetchRevFromGitLab
}: config:
let
  arrange =
    { nyxKey
    , versionNyxPath
    , prev
    , fetcher
    , fetcherData
    , ref ? "main"
    , version ? null
    , newInputs ? null
    , postOverride ? null
    , withUpdateScript ? true
    , withLastModified ? false
    , withLastModifiedDate ? false
    , withCargoDeps ? null
    , cargoLockPath ? builtins.replaceStrings [ "version.json" ] [ "Cargo.lock" ] versionNyxPath
    , withExtraUpdateCommands ? ""
    }:
    let
      versionLocalPath = "${nyx}/${versionNyxPath}";
      current = importJSON versionLocalPath;

      fetchers = { inherit fetchFromGitHub fetchFromGitLab; };
      fullFetcherData = fetcherData // {
        inherit (current) rev hash;
      };
      fetchLatestRev =
        if fetcher == "fetchFromGitHub" then fetchRevFromGitHub
        else if fetcher == "fetchFromGitLab" then fetchRevFromGitLab
        else throw "Unrecognized fetcher ${builtins.toString fetcher}";

      main = prevAttrs:
        let
          src = fetchers.${fetcher} fullFetcherData;

          hasCargo =
            if prevAttrs ? cargoDeps then
              if prevAttrs.cargoDeps.passthru ? lockFile then "lock"
              else "rec"
            else null;

          updateScript = callPackage ./git-update.nix {
            inherit (prevAttrs) pname;
            inherit nyxKey hasCargo withLastModified withLastModifiedDate;
            hasSubmodules = fetcherData.fetchSubmodules or false;
            versionPath = versionNyxPath;
            fetchLatestRev = fetchLatestRev ref fullFetcherData;
            gitUrl = src.gitRepoUrl;
            withExtraCommands = withExtraUpdateCommands;
          };

          common = {
            inherit src;
            version =
              if version == null
              then current.version
              else version;
            passthru = (prevAttrs.passthru or { }) // {
              updateScript =
                if withUpdateScript
                then updateScript
                else null;
            };
          };

          whenCargo =
            lib.attrsets.optionalAttrs (hasCargo != null) {
              cargoDeps =
                if hasCargo == "lock" then
                  withCargoDeps "${nyx}/${cargoLockPath}"
                else
                  prevAttrs.cargoDeps.overrideAttrs (_cargoPrevAttrs: {
                    inherit src;
                    outputHash = current.cargoHash;
                  });
            };
        in
        common // whenCargo;

      optionalPostOverride = lib.lists.optional
        (postOverride != null)
        postOverride;
    in
    {
      final =
        lib.lists.foldl
          (accu: accu.overrideAttrs)
          (if newInputs == null then prev else prev.override newInputs)
          ([ main ] ++ optionalPostOverride);
      inherit current;
    };

  env =
    if builtins.isFunction config
    then config current
    else config;

  arranged = arrange env;
  inherit (arranged) current final;
in
final
