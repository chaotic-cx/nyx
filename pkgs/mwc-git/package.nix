{
  wayland-protocols,
  wayland-scanner,
  libxkbcommon,
  makeWrapper,
  pkg-config,
  libinput,
  wlroots_0_18,
  wayland,
  pixman,
  libxcb,
  libdrm,
  scenefx_0_2,
  libGL,
  meson,
  ninja,
  fetchFromGitHub,
  stdenv,
  lib,
}:

stdenv.mkDerivation rec {
  pname = "mwc-wlr";
  version = "0.1.3";

  src = fetchFromGitHub {
    owner = "dqrk0jeste";
    repo = "mwc";
    rev = "v0.1.3";
    hash = "sha256-O/lFdkfAPC9CSXUkDiAEPWwcfdBUZXXNEEXmSriGzB0=";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [
    wayland-scanner
    makeWrapper
    pkg-config
    meson
    ninja
  ];

  buildInputs = [
    wayland-protocols
    libxkbcommon
    wlroots_0_18
    libinput
    wayland
    libxcb
    libdrm
    pixman
    scenefx_0_2
    libGL
  ];

  postPatch = ''
    substituteInPlace  meson.build --replace-fail "executable('mwc'," """
        add_global_arguments(['-Wno-int-to-pointer-cast',
          '-Wno-int-in-bool-context',
          '-Wno-maybe-uninitialized',
          '-Wno-return-type',
          '-Wno-unused-result'],
          language: 'c')

        executable('mwc',
    """
  '';
  postInstall = ''
    wrapProgram $out/bin/mwc --set MWC_DEFAULT_CONFIG_PATH "$out/share/mwc/default.conf"
  '';

  meta = {
    description = "tiling wayland compositor based on wlroots.";
    homepage = "https://github.com/dqrk0jeste/mwc";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ s0me1newithhand7s ];
    platforms = with lib; [ "x86_64-linux" ];
    mainProgram = "mwc";
  };
}
