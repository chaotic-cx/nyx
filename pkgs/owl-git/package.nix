{ wayland-protocols
, wayland-scanner
, libxkbcommon
, makeWrapper
, pkg-config
, libinput
, wlroots_git
, wayland
, pixman
, libxcb
, libdrm
, fetchFromGitHub
, stdenv
, lib
,
}:

stdenv.mkDerivation rec {
  pname = "owl-wlr";
  version = "unstable-20241209-37efc0c0d";

  src = fetchFromGitHub {
    owner = "dqrk0jeste";
    repo = "owl";
    rev = "37efc0c0d7ebc39b7911bcaec9da1c7cd9a7b6c7";
    hash = "sha256-ZkKwzsi0Cc6Mq6N3jnYajHMS7cdrSccWU+CuP2j86KI=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    wayland-scanner
    makeWrapper
    pkg-config
  ];

  outputs = [
    "out"
  ];

  buildInputs = [
    wayland-protocols
    libxkbcommon
    wlroots_git
    libinput
    wayland
    libxcb
    libdrm
    pixman
  ];

  makeFlags = [
    "PKG_CONFIG=${stdenv.cc.targetPrefix}pkg-config"
    "WAYLAND_SCANNER=wayland-scanner"
    "MANDIR=$out/share/man"
    "PREFIX=$out"
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
