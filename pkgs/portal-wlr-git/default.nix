{
  final,
  prev,
  gitOverride,
  ...
}:

gitOverride {
  newInputs = with final; {
    wayland = wayland_git;
    wayland-protocols = wayland-protocols_git;
    wayland-scanner = wayland-scanner_git;
  };

  nyxKey = "xdg-desktop-portal-wlr_git";
  prev = prev.xdg-desktop-portal-wlr;

  versionNyxPath = "pkgs/portal-wlr-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "emersion";
    repo = "xdg-desktop-portal-wlr";
  };
  ref = "master";

  postOverride = prevAttrs: {
    buildInputs = prevAttrs.buildInputs ++ (with final; [ libxkbcommon ]);
    # https://github.com/emersion/xdg-desktop-portal-wlr/pull/325
    patches = [ ./remotedesktop.patch ] ++ (prevAttrs.patches or [ ]);
    meta = prevAttrs.meta // {
      description = prevAttrs.meta.description + " (includes RemoteDesktop patch)";
    };
  };
}
