{ prev
, gitOverride
, ...
}:

gitOverride (current: {
  nyxKey = "libdrm_git";
  prev = prev.libdrm;

  # Matching the drvName length to use with replaceRuntimeDependencies
  version = builtins.substring 0 (builtins.stringLength prev.libdrm.version) current.rev;

  versionNyxPath = "pkgs/libdrm-git/version.json";
  fetcher = "fetchFromGitLab";
  fetcherData = {
    domain = "gitlab.freedesktop.org";
    owner = "mesa";
    repo = "drm";
  };
})
