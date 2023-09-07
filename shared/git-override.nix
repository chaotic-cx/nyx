{ lib
, callPackage
, importJSON ? lib.trivial.importJSON
}:
{ nyxKey
, versionNyxPath
, versionLocalPath ? null
, prev
, fetcher
, fetchLatestRev
, current ? importJSON versionLocalPath
, version ? current.version
, newInputs ? null
, preOverrides ? [ ]
, postOverrides ? [ ]
, withUpdateScript ? true
}:

let
  main = prevAttrs:
    let
      src = fetcher prevAttrs { inherit (current) rev hash; };

      hasCargo = (prevAttrs ? cargoDeps);

      updateScript = callPackage ./git-update.nix {
        inherit (prevAttrs) pname;
        inherit nyxKey hasCargo;
        versionPath = versionNyxPath;
        fetchLatestRev = fetchLatestRev src;
        gitUrl = src.gitRepoUrl;
      };

      common = {
        inherit version src;
        passthru = (prevAttrs.passthru or { }) // {
          updateScript =
            if withUpdateScript
            then updateScript
            else null;
        };
      };

      whenCargo =
        lib.attrsets.optionalAttrs hasCargo {
          cargoDeps = prevAttrs.cargoDeps.overrideAttrs (_cargoPrevAttrs: {
            inherit (prevAttrs) src;
            outputHash = current.cargoHash;
          });
        };
    in
    common // whenCargo;
in
lib.lists.foldl
  (accu: accu.overrideAttrs)
  (if newInputs == null then prev else prev.override newInputs)
  (preOverrides ++ [ main ] ++ postOverrides)
