{
  final,
  gitOverride,
  ...
}:

gitOverride {
  nyxKey = "distrobox_git";
  prev = final.callPackage ./package.nix { };

  versionNyxPath = "pkgs/distrobox-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "89luca89";
    repo = "distrobox";
  };

  postOverride = prevAttrs: {
    ldflags = [
      "-X"
      "github.com/89luca89/distrobox/pkg/version.Version=${prevAttrs.version}"
    ];
  };
}
