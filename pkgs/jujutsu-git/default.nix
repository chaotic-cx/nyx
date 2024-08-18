{ prev, gitOverride, nyxUtils, ... }:

gitOverride {
  nyxKey = "jujutsu_git";
  prev = prev.jujutsu;

  versionNyxPath = "pkgs/jujutsu-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "martinvonz";
    repo = "jj";
  };

  postOverride = prevAttrs: {
    cargoDeps = prevAttrs.cargoDeps.overrideAttrs(cargoPrevAttrs: {
      patches = nyxUtils.removeByURL "https://github.com/martinvonz/jj/commit/38f6ee89183d886e432472c5888908c9900c9c18.patch?full_index=1" cargoPrevAttrs.patches;
    });
    patches = nyxUtils.removeByURL "https://github.com/martinvonz/jj/commit/38f6ee89183d886e432472c5888908c9900c9c18.patch?full_index=1" prevAttrs.patches;
  };
}
