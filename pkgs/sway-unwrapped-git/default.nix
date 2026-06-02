{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  newInputs = with final; {
    libdrm = libdrm_git;
    wayland = wayland_git;
    wayland-protocols = wayland-protocols_git;
    wayland-scanner = wayland-scanner_git;
    wlroots_0_20 = final.wlroots_git;
  };

  nyxKey = "sway-unwrapped_git";
  prev = prev.sway-unwrapped;

  versionNyxPath = "pkgs/sway-unwrapped-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "swaywm";
    repo = "sway";
  };
  ref = "master";

  postOverride = prevAttrs: {
    patches =
      (builtins.filter (p: !prev.lib.hasSuffix "load-configuration-from-etc.patch" (toString p)) (
        prevAttrs.patches or [ ]
      ))
      # Adapted patch for NIX_SYSCONFDIR fallback
      ++ [ ./load-configuration-from-etc.patch ];
  };
}
