{
  lib,
  stdenv,
  fetchurl,
  wrapGAppsHook3,
  autoPatchelfHook,
  alsa-lib,
  curl,
  dbus-glib,
  gtk3,
  libXtst,
  libva,
  pciutils,
  pipewire,
  adwaita-icon-theme,
  patchelfUnstable, # have to use patchelfUnstable to support --no-clobber-old-sections
  undmg,
  writeText,
}:

let
  inherit (lib.importJSON ./version.json) version sources;

  binaryName = "firedragon";
  policies = {
    DisableAppUpdate = true;
  };

  policiesJson = writeText "firedragon-policies.json" (builtins.toJSON { inherit policies; });

in
stdenv.mkDerivation (finalAttrs: {
  pname = "firedragon-catppuccin-bin-unwrapped";
  inherit version;

  src = fetchurl {
    inherit (sources.${stdenv.hostPlatform.system}) url sha256;
  };

  sourceRoot = lib.optional stdenv.hostPlatform.isDarwin ".";

  nativeBuildInputs = [
    wrapGAppsHook3
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    autoPatchelfHook
    patchelfUnstable
  ]
  ++ lib.optionals stdenv.hostPlatform.isDarwin [
    undmg
  ];

  buildInputs = lib.optionals (!stdenv.hostPlatform.isDarwin) [
    gtk3
    adwaita-icon-theme
    alsa-lib
    dbus-glib
    libXtst
  ];

  runtimeDependencies = [
    curl
    pciutils
  ]
  ++ lib.optionals (!stdenv.hostPlatform.isDarwin) [
    libva.out
  ];

  appendRunpaths = lib.optionals (!stdenv.hostPlatform.isDarwin) [
    "${pipewire}/lib"
  ];

  # Firefox uses "relrhack" to manually process relocations from a fixed offset
  patchelfFlags = [ "--no-clobber-old-sections" ];

  # don't break code signing
  dontFixup = stdenv.hostPlatform.isDarwin;

  installPhase = ''
    runHook preInstall
  ''
  + (
    if stdenv.hostPlatform.isDarwin then
      ''
        # it's disabled, so remove these unused files
        rm -v \
          FireDragon.app/Contents/Resources/updater.ini \
          FireDragon.app/Contents/Library/LaunchServices/org.mozilla.updater
        rm -rvf FireDragon.app/Contents/MacOS/updater.app

        mkdir -p $out/Applications
        mv FireDragon.app $out/Applications/
      ''
    else
      ''
        # it's disabled, so remove these unused files
        rm -v updater icons/updater.png updater.ini update-settings.ini

        mkdir -p "$prefix/lib" "$prefix/bin"
        cp -r . "$prefix/lib/firedragon-catppuccin-bin-${finalAttrs.version}"
        ln -s "$prefix/lib/firedragon-catppuccin-bin-${finalAttrs.version}/firedragon" "$out/bin/${binaryName}"

        # See: https://github.com/mozilla/policy-templates/blob/master/README.md
        mkdir -p "$out/lib/firedragon-catppuccin-bin-${finalAttrs.version}/distribution";
        ln -s ${policiesJson} "$out/lib/firedragon-catppuccin-bin-${finalAttrs.version}/distribution/policies.json";
      ''
  )
  + ''
    runHook postInstall
  '';

  passthru = {
    inherit binaryName gtk3;
    applicationName = "FireDragon";
    libName = "firedragon-catppuccin-bin-${finalAttrs.version}";
    ffmpegSupport = true;
    gssSupport = true;
  };

  meta = {
    changelog = "https://gitlab.com/garuda-linux/firedragon/firedragon12/-/blob/main/CHANGELOG.md";
    description = "Floorp fork with custom branding and opinionated defaults, Catppuccin variant";
    homepage = "https://firedragon.garudalinux.org/";
    license = with lib.licenses; [
      mpl20
      mit
    ];
    platforms = builtins.attrNames sources;
    hydraPlatforms = [ ];
    maintainers = with lib.maintainers; [
      dr460nf1r3
    ];
    mainProgram = "firedragon";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
