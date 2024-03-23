{ prev, gitOverride, ... }:

gitOverride {
  nyxKey = "nix-flake-schemas_git";
  prev = prev.nixVersions.nix_2_20;

  versionNyxPath = "pkgs/nix-flake-schemas-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "DeterminateSystems";
    repo = "nix-src";
  };
  ref = "flake-schemas";

  postOverride = prevAttrs: {
    doInstallCheck = false;
    meta = prevAttrs.meta // {
      homepage = "https://determinate.systems/posts/flake-schemas";
      description = "Nix from the branch with flake-schemas";
      longDescription = prevAttrs.meta.longDescription + "(from the branch with flake-schemas).";
    };
  };
}
