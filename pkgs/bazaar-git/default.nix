{
  lib,
  callPackage,
  blueprint-compiler,
  desktop-file-utils,
  fetchFromGitHub,
  fetchurl,
  flatpak,
  flatpak-xdg-utils,
  glib,
  libxmlb,
  libglycin,
  cmake,
  gobject-introspection,
  gtk4,
  libdex,
  libadwaita,
  appstream,
  meson,
  ninja,
  pkg-config,
  libyaml,
  libsoup_3,
  stdenv,
  wrapGAppsHook4,
  json-glib,
}:

let
  current = lib.trivial.importJSON ./version.json;

  libdex_next =
    if libdex.version == "0.10.1" then
      libdex.overrideAttrs (_prevAttrs: rec {
        version = "0.11.1";
        src = fetchurl {
          url = "mirror://gnome/sources/libdex/${lib.versions.majorMinor version}/libdex-${version}.tar.xz";
          hash = "sha256-lCUKLYPm9z06yJcvGkOAFSNqRltWywBeDmv7nUlIc58=";
        };
      })
    else
      libdex;
in
stdenv.mkDerivation rec {
  pname = "bazaar";
  inherit (current) version;

  src = fetchFromGitHub {
    inherit (current) rev hash;
    owner = "kolunmi";
    repo = "bazaar";
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
    libdex_next
    appstream
    libxmlb
    libglycin
    libyaml
    json-glib
    libsoup_3
  ];

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit pname;
    nyxKey = "bazaar_git";
    versionPath = "pkgs/bazaar-git/version.json";
    fetchLatestRev = callPackage ../../shared/github-rev-fetcher.nix { } "master" src;
    gitUrl = src.gitRepoUrl;
  };

  meta = {
    changelog = "https://github.com/kolunmi/bazaar/commits/master/";
    description = "A new app store idea for GNOME";
    homepage = "https://github.com/kolunmi/bazaar";
    license = lib.licenses.gpl3Plus;
    mainProgram = "bazaar";
    maintainers = with lib.maintainers; [ jumpyvi ];
    platforms = lib.platforms.linux;
  };
}
