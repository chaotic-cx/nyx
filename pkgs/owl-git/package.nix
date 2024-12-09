{
  wayland-protocols,
  wayland-scanner,
  libxkbcommon,
  makeWrapper,
  pkg-config,
  libinput,
  wlroots_git,
  wayland,
  pixman,
  libxcb,
  libdrm,

  fetchgit,
  stdenv,
  pkgs,
  lib,
}:

stdenv.mkDerivation rec {
  pname = "owl_git";

  src = fetchgit {
    url = "https://github.com/dqrk0jeste/owl";
    hash = "sha256-ZkKwzsi0Cc6Mq6N3jnYajHMS7cdrSccWU+CuP2j86KI=";
  };

  nativeBuildInputs = [
    pkg-config
    wayland-scanner
    makeWrapper
  ];

  outputs = [
    "out"
  ];

  buildInputs = [
    libinput
    libxcb
    libdrm
    libxkbcommon
    pixman
    wayland
    wayland-protocols
    wlroots_git
  ];

  makeFlags = [
    "PKG_CONFIG=${stdenv.cc.targetPrefix}pkg-config"
    "WAYLAND_SCANNER=wayland-scanner"
    "PREFIX=$out"
    "MANDIR=$out/share/man"
  ];

  strictDeps = true;

  depsBuildBuild = [
    pkg-config
  ];

  postInstall = ''
    wrapProgram $out/bin/owl --set OWL_DEFAULT_CONFIG_PATH "$out/share/default.conf"
  '';

  buildPhase = ''
    make
  '';

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p $out/share
    cp -r build/owl $out/bin/
    cp -r build/owl-ipc $out/bin/
    cp -r default.conf $out/share/
  '';

  # HUUUUUUUUUGE thanks to https://github.com/dqrk0jeste ^^^

  __structuredAttrs = true;

  meta = {
    description = "tiling wayland compositor based on wlroots.";
    homepage = "https://github.com/dqrk0jeste/owl";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ s0me1newithhand7s ];
    platforms = with lib; [ "x86_64-linux" ];
  };
}
