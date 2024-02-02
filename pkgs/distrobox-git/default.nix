{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "distrobox_git";
  prev = prev.distrobox;

  versionNyxPath = "pkgs/distrobox-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "89luca89";
    repo = "distrobox";
  };

  postOverride = prevAttrs: {
    patches = nyxUtils.removeByBaseName "always-mount-nix.patch" prevAttrs.patches;
  };
}
