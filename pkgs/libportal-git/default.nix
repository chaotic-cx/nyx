{ final, prev, gitOverride, ... }:

gitOverride {
  nyxKey = "libportal_git";
  prev = prev.libportal;

  versionNyxPath = "pkgs/libportal-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "flatpak";
    repo = "libportal";
  };

  postOverride = prevAttrs: {
    mesonFlags = with final; [
      (lib.mesonEnable "backend-qt6" false)
    ] ++ prevAttrs.mesonFlags;
  };
}
