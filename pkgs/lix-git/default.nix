{ final, prev, gitOverride, nyxUtils, ... }:

gitOverride {
  nyxKey = "lix_git";
  prev = prev.lix;

  newInputs = {
    lix-doc = null;
    enableDocumentation = false;
  };

  versionNyxPath = "pkgs/lix-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "lix-project";
    repo = "lix";
  };
  ref = "main";

  postOverride = prevAttrs: {
    patches = nyxUtils.removeByURL "https://git.lix.systems/lix-project/lix/commit/ca2b514e20de12b75088b06b8e0e316482516401.patch"
      (nyxUtils.removeByURL "https://git.lix.systems/lix-project/lix/commit/ed51a172c69996fc6f3b7dfaa86015bff50c8ba8.patch" prevAttrs.patches);
    nativeBuildInputs = with final; [ rustc ] ++ prevAttrs.nativeBuildInputs;
    postPatch =
      # I did this the worst way possible, sorry! There are sure better ways to override the cargoHash here.
      let
        cargoDeps = {
          autocfg = { version = "1.1.0"; hash = "sha256-1GiAK6sXy8DMV16bBT9B5yqja/prf1XjUp/6QxYbl/o="; };
          countme = { version = "3.0.1"; hash = "sha256-dwS1/dF7GK4xxMHaWi4DBaK/F7UkkwCp7p7XtyEUxjY="; };
          dissimilar = { version = "1.0.9"; hash = "sha256-WfjnnR+/dr373jIekCcUv2xJ34in3ab8aC/Cl5Imli0="; };
          expect-test = { version = "1.5.0"; hash = "sha256-ngvgpWEzWBXgbat8YuUDUxNMeW56YVVAKmS8/2a2peA="; };
          hashbrown = { version = "0.14.5"; hash = "sha256-5SdEI+F7fJ/CC25+IIUy+bGYJdgt/WFXCLcO3YPfQfE="; };
          memoffset = { version = "0.9.1"; hash = "sha256-SIAWv65FewNtmWCS9stEhndhHOREnpcM6vQmlSA/IYo="; };
          once_cell = { version = "1.19.0"; hash = "sha256-P9sSskdrWV+TWMUWGqRnwkOIWcqhNt7IbCb90u/he5I="; };
          rnix = { version = "0.11.0"; hash = "sha256-uzXO2+tw4Myr7yoxvP8K69EU8ZVmCGMAuPQscl/Cy18="; };
          rowan = { version = "0.15.16"; hash = "sha256-ClQrAlP6RuYy0nodxc97kw3k34ZZ3G5yC2R/xyFHrj0="; };
          rustc-hash = { version = "1.1.0"; hash = "sha256-CNQ/eqawjUnzgs3mp5ggR8NCbblJsUJLxLfsmuEsbOI="; };
          text-size = { version = "1.1.1"; hash = "sha256-8Yqhh4ObK9sa0vo16tjEwpdrZOQ2PDhtRawPfuhckjM="; };
        };

        cargoFetch = who: { version, hash }: final.fetchurl {
          url = "https://crates.io/api/v1/crates/${who}/${version}/download";
          inherit hash;
        };

        cargoSubproject = who: data: ''
          ln -s ${cargoFetch who data} subprojects/packagecache/${who}-${data.version}.tar.gz
        '';

        cargoAll =
          builtins.attrValues (builtins.mapAttrs cargoSubproject cargoDeps);
      in
      prevAttrs.postPatch + ''
        mkdir -p subprojects/packagecache
        ${builtins.concatStringsSep "\n" cargoAll}
      ''
    ;
  };
}
