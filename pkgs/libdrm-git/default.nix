{ prev
, gitOverride
, ...
}:

gitOverride {
  nyxKey = "libdrm_git";
  prev = prev.libdrm;

  versionNyxPath = "pkgs/libdrm-git/version.json";
  fetcher = "fetchFromGitLab";
  fetcherData = {
    domain = "gitlab.freedesktop.org";
    owner = "mesa";
    repo = "drm";
  };
}
