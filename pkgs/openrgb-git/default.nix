{
  lib,
  stdenv,
  fetchFromGitLab,
  qt6Packages,
  libusb1,
  hidapi,
  pkg-config,
  mbedtls,
  symlinkJoin,
  callPackage,
}:

let
  current = lib.importJSON ./manifest.json;
in
stdenv.mkDerivation (finalAttrs: {
  pname = "openrgb";
  inherit (current) version;

  src = fetchFromGitLab {
    owner = "CalcProgrammer1";
    repo = "OpenRGB";
    inherit (current) rev hash;
  };

  nativeBuildInputs = [
    pkg-config
  ]
  ++ (with qt6Packages; [
    qmake
    wrapQtAppsHook
  ]);

  buildInputs = [
    libusb1
    hidapi
    mbedtls
  ]
  ++ (with qt6Packages; [
    qtbase
    qttools
  ]);

  postPatch = ''
    substituteInPlace OpenRGB.pro \
      --replace-fail "lrelease" "${qt6Packages.qttools.dev}/bin/lrelease"
  '';

  postInstall = ''
    mkdir -p $out/lib/udev/rules.d
    $out/bin/openrgb --generate-udev-rules $out/lib/udev/rules.d/60-openrgb.rules
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    HOME=$TMPDIR $out/bin/openrgb --help > /dev/null
  '';

  passthru.withPlugins =
    plugins:
    let
      pluginsDir = symlinkJoin {
        name = "openrgb-plugins";
        paths = plugins;
        # Remove all library version symlinks except one,
        # or they will result in duplicates in the UI.
        # We leave the one pointing to the actual library, usually the most
        # qualified one (eg. libOpenRGBHardwareSyncPlugin.so.1.0.0).
        postBuild = ''
          for f in $out/lib/*; do
            if [ "$(dirname $(readlink "$f"))" == "." ]; then
              rm "$f"
            fi
          done
        '';
      };
    in
    finalAttrs.finalPackage.overrideAttrs (old: {
      qmakeFlags = old.qmakeFlags or [ ] ++ [
        # Welcome to Escape Hell, we have backslashes
        ''DEFINES+=OPENRGB_EXTRA_PLUGIN_DIRECTORY=\\\""${
          lib.escape [ "\\" "\"" " " ] (toString pluginsDir)
        }/lib\\\""''
      ];
    });

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit (finalAttrs) pname;
    nyxKey = "openrgb_git";
    manifestPath = "pkgs/openrgb-git/manifest.json";
    fetchLatestRev = callPackage ../../shared/github-rev-fetcher.nix { } "master" finalAttrs.src;
    gitUrl = finalAttrs.src.gitRepoUrl;
  };

  meta = {
    description = "Open source RGB lighting control";
    homepage = "https://gitlab.com/CalcProgrammer1/OpenRGB";
    license = lib.licenses.gpl2Plus;
    platforms = lib.platforms.linux;
    maintainers = with lib.maintainers; [ johnrtitor ];
    mainProgram = "openrgb";
  };
})
