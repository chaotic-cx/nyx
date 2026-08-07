{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "swaylock-plugin_git";
  prev = prev.swaylock;

  manifestPath = "pkgs/swaylock-plugin-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "mstoeckl";
    repo = "swaylock-plugin";
  };

  postOverride = prevAttrs: {
    buildInputs = prevAttrs.buildInputs ++ [ final.systemd ];
  };
}
