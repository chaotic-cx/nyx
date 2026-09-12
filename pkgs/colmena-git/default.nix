{
  prev,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "colmena_git";
  prev = prev.colmena;

  manifestPath = "pkgs/colmena-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "nix-community";
    repo = "colmena";
  };

  postOverride = {
    patches = [ ];
    doInstallCheck = false;
  };
}
