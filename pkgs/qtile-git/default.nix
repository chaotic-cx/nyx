{
  final,
  gitOverride,
  prev,
  flakes,
  ...
}:

gitOverride {
  nyxKey = "qtile-module_git";
  prev = prev.python3Packages.qtile;

  newInputs = {
    wlroots = final.wlroots_0_20;
  };

  versionNyxPath = "pkgs/qtile-git/version.json";
  fetcher = "fetchFromGitHub";
  fetcherData = {
    owner = "qtile";
    repo = "qtile";
  };
  ref = "master";

  version = prev.python3Packages.qtile.version + ".99";

  postOverride = prevAttrs: {
    name = prevAttrs.name + ".99";
    patches = [ ];
    postPatch = "";
    doCheck = false;
    # qtile.desktop in master is not yet in sync with nixpkgs' qtile module
    # (still references the dropped qtile-wayland.desktop and a user systemd
    # service). Keep the DM session working until nixpkgs catches up.
    postInstall = ''
      substituteInPlace resources/qtile.desktop \
        --replace-fail 'Exec=/bin/sh -c "systemctl --user import-environment DISPLAY WAYLAND_DISPLAY XAUTHORITY XDG_SEAT XDG_VTNR XDG_SESSION_ID XDG_SESSION_TYPE XDG_SESSION_CLASS XDG_SESSION_DESKTOP XDG_CURRENT_DESKTOP DESKTOP_SESSION; exec systemctl --user start --wait qtile.service"' \
        'Exec=qtile start'
      install resources/qtile.desktop -Dt $out/share/xsessions
      install resources/qtile.desktop -Dt $out/share/wayland-sessions
    '';
    passthru = prevAttrs.passthru // {
      tests.smoke-test = import ./test.nix {
        inherit (flakes) nixpkgs;
        chaotic = flakes.self;
      } final;
    };
  };
}
