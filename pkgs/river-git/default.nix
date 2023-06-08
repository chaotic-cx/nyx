{ inputs
, nyxUtils
, prev
, final
, ...
}:
let
  src = builtins.fromJSON (builtins.readFile ./src.json);
  zig-wayland = final.fetchFromGitHub {
    owner = "ifreund";
    repo = "zig-wayland";
    inherit (src.zig-wayland) rev hash;
  };
  zig-pixman = final.fetchFromGitHub {
    owner = "ifreund";
    repo = "zig-pixman";
    inherit (src.zig-pixman) rev hash;
  };
  zig-xkbcommon = final.fetchFromGitHub {
    owner = "ifreund";
    repo = "zig-xkbcommon";
    inherit (src.zig-xkbcommon) rev hash;
  };
  zig-wlroots = final.fetchFromGitHub {
    owner = "swaywm";
    repo = "zig-wlroots";
    inherit (src.zig-wlroots) rev hash;
  };
in
prev.river.overrideAttrs (prevAttrs: rec {
  version = nyxUtils.gitToVersion src;
  src = inputs.river-git-src;
  postUnpack = ''
    cp -R --no-preserve=mode,ownership ${zig-wayland}/* source/deps/zig-wayland
    cp -R --no-preserve=mode,ownership ${zig-pixman}/* source/deps/zig-pixman
    cp -R --no-preserve=mode,ownership ${zig-xkbcommon}/* source/deps/zig-xkbcommon
    cp -R --no-preserve=mode,ownership ${zig-wlroots}/* source/deps/zig-wlroots
    patchShebangs source
  '';
  passthru.updateScript = ./update.sh;
})
