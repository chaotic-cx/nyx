{ enableXWayland ? true
, final
, prev
, gitOverride
, ...
}:

let
  src = {
    domain = "gitlab.freedesktop.org";
    owner = "wlroots";
    repo = "wlroots";
  };
in
gitOverride {
  newInputs = with final; {
    inherit enableXWayland;
    wayland-protocols = wayland-protocols_git;
  };
  nyxKey = "wlroots_git";
  versionNyxPath = "pkgs/wlroots-git/version.json";
  versionLocalPath = ./version.json;
  prev = prev.wlroots_0_16;
  fetcher =
    _prevAttrs: finalArgs: final.fetchFromGitLab (src // finalArgs);
  fetchLatestRev = _src: final.callPackage ../../shared/gitlab-rev-fetcher.nix { inherit src; ref = "master"; };

  postOverrides = [
    (prevAttrs: {
      buildInputs = prevAttrs.buildInputs ++ (with final; [ hwdata libdisplay-info ]);
      postPatch = "";
    })
  ];
}
