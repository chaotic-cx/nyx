{
  lib,
  stdenvNoCC,

  callPackage,
  fetchFromGitLab,
  fetchurl,

  applet-window-title,
  catppuccin-cursors,
  catppuccin-gtk,
  catppuccin,
  catppuccin-kde,
  kde-rounded-corners,
  kdePackages,
  plasma-panel-colorizer,
  plasma-plugin-blurredwallpaper,
  tela-circle-icon-theme,
}:

let
  current = lib.trivial.importJSON ./manifest.json;

  srcMeta = {
    inherit (current) rev hash;
    group = "garuda-linux";
    owner = "themes-and-settings/settings";
    repo = "garuda-mokka";
  };

  gitUrl = "https://gitlab.com/${srcMeta.group}/${srcMeta.owner}/${srcMeta.repo}";

  distributorLogo = fetchurl {
    url = "https://gitlab.com/garuda-linux/themes-and-settings/artwork/garuda-icons/-/raw/master/usr/share/icons/garuda/distributor-logo-garuda-cat.svg";
    hash = "sha256-6waflwkvh+nC1ZXOdhWPufAb/OFWur0eJWAjs6AR9MY=";
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "mokka-kde-theme";
  inherit (current) version;

  src = fetchFromGitLab srcMeta;

  buildInputs = [
    applet-window-title
    catppuccin-cursors
    catppuccin-gtk
    (catppuccin.override {
      accent = "mauve";
      variant = "mocha";
      themeList = [
        "bat"
        "btop"
        "kvantum"
      ];
    })
    (catppuccin-kde.override {
      accents = [ "mauve" ];
      flavour = [ "mocha" ];
      winDecStyles = [ "classic" ];
    })
    kde-rounded-corners
    kdePackages.applet-window-buttons6
    plasma-panel-colorizer
    plasma-plugin-blurredwallpaper
    tela-circle-icon-theme
  ];

  dontWrapQtApps = true;

  postPatch = ''
    for file in $(find ./* \( -type f \( -name "*.profile" -o -name "*.conf" -o ! -name "*.*" \) \) -o -type l ); do
      if [ -h $file ]; then
        ln -fs $(readlink $file | sed -e 's|/usr/share|/run/current-system/sw/share|g') $file
      else
        substituteInPlace $file --replace "/usr/bin" "/run/current-system/sw/bin" --replace "/usr/share" "/run/current-system/sw/share"
      fi
    done

    substituteInPlace etc/skel/.config/autostart/initial-setup.desktop \
      --replace "/etc/skel/.config/autostart/initial-setup.sh" "~/.config/autostart/initial-setup.sh"

    substituteInPlace usr/share/fastfetch/presets/mokka.jsonc \
      --replace "/usr/share/icons/garuda/mokka-fastfetch.png" "/run/current-system/sw/share/icons/garuda/mokka-fastfetch.png"

    substituteInPlace usr/share/plasma/layout-templates/org.garuda.desktop.defaultPanel/contents/layout.js usr/share/plasma/layout-templates/org.garuda.desktop.defaultDock/contents/layout.js \
      --replace "/usr/share" "/run/current-system/sw/share" \
      --replace "applications:garuda-toolbox.desktop," "" \
      --replace ",applications:snapper-tools.desktop" "" \
      --replace ",applications:octopi.desktop" ""

    substituteInPlace usr/share/plasma/layout-templates/org.garuda.desktop.defaultPanel/contents/layout.js \
      --replace '"distributor-logo-garuda"' '"/run/current-system/sw/share/icons/garuda/distributor-logo-garuda-cat.svg"'

    substituteInPlace usr/share/plasma/layout-templates/org.garuda.desktop.defaultPanel/contents/layout.js usr/share/plasma/layout-templates/org.garuda.desktop.defaultDock/contents/layout.js usr/share/plasma/look-and-feel/MokkaKitty/contents/layouts/org.kde.plasma.desktop-layout.js \
      --replace "plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets" "mokka-panel-colorizer-presets"

    substituteInPlace usr/share/plasma/look-and-feel/MokkaKitty/contents/layouts/org.kde.plasma.desktop-layout.js \
      --replace "/usr/share" "/run/current-system/sw/share"

    substituteInPlace etc/skel/.config/kscreenlockerrc \
      --replace "wallpapers/garuda-mokka/City-horizon Mocha.jpg" "wallpapers/Mokka-tree/contents/images/3840x2160.jpg"

    substituteInPlace usr/share/plasma/look-and-feel/Mokka/contents/defaults usr/share/plasma/look-and-feel/MokkaKitty/contents/defaults etc/skel/.config/gtk-3.0/settings.ini etc/skel/.config/gtk-4.0/settings.ini \
      --replace "Tela-circle-dracula-dark" "Tela-circle-dark"

    substituteInPlace usr/share/plasma/look-and-feel/Mokka/contents/defaults \
      --replace "wallpapers/garuda-mokka/Mokka-tree.jpg" "wallpapers/Mokka-tree/contents/images/3840x2160.jpg"
  '';

  installPhase = ''
    runHook preInstall
    install -d $out/skel
    cp -r etc/skel $out/
    install -d $out/share
    cp -r usr/share/* $out/share/
    install -Dm644 ${distributorLogo} $out/share/icons/garuda/distributor-logo-garuda-cat.svg

    # Merging this package's plasmoid fragment with plasma-panel-colorizer in
    # system-path produces a symlink tree that KPackage rejects ("path traversal attempt", applet fails to load)
    mkdir -p $out/share/mokka-panel-colorizer-presets
    cp -r usr/share/plasma/plasmoids/luisbocanegra.panel.colorizer/contents/ui/presets/* $out/share/mokka-panel-colorizer-presets/
    rm -rf $out/share/plasma/plasmoids

    runHook postInstall
  '';

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit (finalAttrs) pname;
    nyxKey = "mokka-kde-theme";
    manifestPath = "pkgs/mokka-kde-theme/manifest.json";
    fetchLatestRev = callPackage ../../shared/gitlab-rev-fetcher.nix { } "main" srcMeta;
    inherit gitUrl;
  };

  meta = with lib; {
    description = "The default Garuda Mokka theme";
    homepage = "https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-mokka";
    license = licenses.gpl3Only;
    maintainers = [ maintainers.dr460nf1r3 ];
    platforms = platforms.linux;
  };
})
