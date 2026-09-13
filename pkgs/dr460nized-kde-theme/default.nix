{
  lib,
  stdenvNoCC,

  callPackage,
  fetchFromGitLab,
  fetchurl,

  applet-window-title,
  beautyline-icons,
  kde-rounded-corners,
  kdePackages,
  plasma-panel-colorizer,
  plasma-plugin-blurredwallpaper,
  sweet-nova,
}:

let
  current = lib.trivial.importJSON ./manifest.json;

  srcMeta = {
    inherit (current) rev hash;
    group = "garuda-linux";
    owner = "themes-and-settings/settings";
    repo = "garuda-dr460nized";
  };

  gitUrl = "https://gitlab.com/${srcMeta.group}/${srcMeta.owner}/${srcMeta.repo}.git";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "dr460nized-kde-theme";
  inherit (current) version;

  src = fetchFromGitLab srcMeta;

  maldrakor = fetchurl {
    url = "https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-dr460nized/-/raw/main/usr/share/wallpapers/Maldrakor/contents/3840x1920.jpg";
    hash = "sha256-H7qwdrKKLuYXQbJg+jTxOAZNKMn3iCTsQtyl1kfFNvc=";
  };

  dontWrapQtApps = true;

  buildInputs = [
    applet-window-title
    beautyline-icons
    kde-rounded-corners
    kdePackages.applet-window-buttons6
    plasma-panel-colorizer
    plasma-plugin-blurredwallpaper
    sweet-nova
  ];

  postPatch = ''
    for file in $(find ./* \( -type f \( -name "*.profile" -o -name "*.conf" -o ! -name "*.*" \) \) -o -type l ); do
      if [ -h "$file" ]; then
        ln -fs "$(readlink "$file" | sed -e 's|/usr/share|/run/current-system/sw/share|g')" "$file"
      else
        substituteInPlace "$file" \
          --replace "/usr/bin" "/run/current-system/sw/bin" \
          --replace "/usr/share" "/run/current-system/sw/share"
      fi
    done

    substituteInPlace \
      usr/share/plasma/look-and-feel/Dr460nized/contents/layouts/org.kde.plasma.desktop-layout.js \
      usr/share/plasma/layout-templates/org.garuda.desktop.defaultDock/contents/layout.js \
      --replace "applications:garuda-welcome.desktop," "" \
      --replace "applications:garuda-toolbox.desktop," "" \
      --replace "applications:snapper-tools.desktop," "" \
      --replace ",applications:octopi.desktop" ""

    substituteInPlace usr/share/plasma/layout-templates/org.garuda.desktop.defaultPanel/contents/layout.js \
      usr/share/plasma/layout-templates/org.garuda.desktop.defaultDock/contents/layout.js \
      --replace "/usr/share" "/run/current-system/sw/share" \
      --replace "plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets" "dr460nized-panel-colorizer-presets"

    substituteInPlace usr/share/fastfetch/presets/dr460nized.jsonc \
      --replace "/usr/share" "/run/current-system/sw/share"
  '';

  installPhase = ''
    runHook preInstall

    install -d $out/skel
    if [ -d etc/skel ]; then
      cp -r etc/skel/. $out/skel/
    fi

    install -d $out/share
    if [ -d usr/share ]; then
      cp -r usr/share/. $out/share/
    fi

    install -Dm644 $maldrakor \
      $out/share/wallpapers/Maldrakor/contents/3840x1920.jpg

    # Merging this package's plasmoid fragment with plasma-panel-colorizer in
    # system-path produces a symlink tree that KPackage rejects ("path traversal attempt", applet fails to load)
    mkdir -p $out/share/dr460nized-panel-colorizer-presets
    cp -r usr/share/plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets/* $out/share/dr460nized-panel-colorizer-presets/
    rm -rf $out/share/plasma/plasmoids

    runHook postInstall
  '';

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit (finalAttrs) pname;
    nyxKey = "dr460nized-kde-theme";
    manifestPath = "pkgs/dr460nized-kde-theme/manifest.json";
    fetchLatestRev = callPackage ../../shared/gitlab-rev-fetcher.nix { } "main" srcMeta;
    inherit gitUrl;
  };

  meta = {
    description = "The default Garuda dr460nized theme";
    homepage = "https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-dr460nized";
    license = lib.licenses.gpl3Only;
    maintainers = [ lib.maintainers.dr460nf1r3 ];
    platforms = lib.platforms.linux;
  };
})
