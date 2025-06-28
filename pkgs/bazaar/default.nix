{ lib, blueprint-compiler, desktop-file-utils, fetchFromGitHub, flatpak
, flatpak-xdg-utils, glib, libxmlb, libglycin, cmake, gobject-introspection
, gtk4, libdex, libadwaita, appstream, meson, ninja, nix-update-script
, pkg-config, libyaml, libsoup_3, stdenv, wrapGAppsHook4, json-glib, curl, fetchurl }:

stdenv.mkDerivation (finalAttrs: {
  pname = "bazaar";
  version = "v0.1.0"; # First pre-release version

  src = fetchFromGitHub {
    owner = "kolunmi";
    repo = "bazaar";
    tag = finalAttrs.version;
    hash = "sha256-QzzWj6KjyKNMBHQ/RqvUSL6QeokgvK2Fc+23kkt3SMM=";
  };

  nativeBuildInputs = [
    blueprint-compiler
    desktop-file-utils
    meson
    cmake
    ninja
    pkg-config
    wrapGAppsHook4
    gobject-introspection
  ];

  buildInputs = [
    flatpak
    flatpak-xdg-utils
    glib
    gtk4
    libadwaita
    libdex
    appstream
    libxmlb
    libglycin
    libyaml
    json-glib
    libsoup_3
  ];

  passthru.updateScript = nix-update-script { };

  meta = {
    changelog = "https://github.com/kolunmi/bazaar/commits/master/";
    description = "A new app store idea for GNOME";
    homepage = "https://github.com/kolunmi/bazaar";
    license = lib.licenses.gpl3Plus;
    mainProgram = "bazaar";
    maintainers = with lib.maintainers; [ jumpyvi ];
    platforms = lib.platforms.linux;
  };
})
