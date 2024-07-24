{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "nix-flake-schemas_git";
  prev = prev.nixVersions.nix_2_22;

  versionNyxPath = "pkgs/nix-flake-schemas-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "DeterminateSystems";
    repo = "nix-src";
  };
  ref = "flake-schemas";

  postOverride = prevAttrs: {
    doInstallCheck = false;
    configureFlags = prevAttrs.configureFlags ++ [
      "--with-default-flake-schemas=${final.fetchFromGitHub {
        owner = "DeterminateSystems";
        repo = "flake-schemas";
        rev = "v0.1.3";
        hash = "sha256-c2AZH9cOnSpPXV8Lwy19/I8EgW7G+E+Zh6YQBZZwzxI=";
      }}"
    ];
    meta = prevAttrs.meta // {
      homepage = "https://determinate.systems/posts/flake-schemas";
      description = "Nix from the branch with flake-schemas";
      longDescription = prevAttrs.meta.longDescription + "(from the branch with flake-schemas).";
    };
  };
}
