{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "libportal_git";
  prev = prev.libportal;

  manifestPath = "pkgs/libportal-git/manifest.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "flatpak";
    repo = "libportal";
  };

  postOverride = prevAttrs: {
    mesonFlags =
      with final;
      [
        (lib.mesonEnable "backend-qt6" false)
      ]
      ++ prevAttrs.mesonFlags;

    patches = builtins.filter (
      patch:
      !(prev.lib.hasSuffix "libportal-fix-qt6.9-private-api-usage.patch" (baseNameOf (toString patch)))
    ) (prevAttrs.patches or [ ]);
  };
}
