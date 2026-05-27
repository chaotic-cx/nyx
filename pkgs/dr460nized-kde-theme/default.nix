{
  lib,
  stdenvNoCC,

  fetchgit,
  fetchurl,
  callPackage,

  beautyline-icons,
  plasma-plugin-blurredwallpaper,
  sweet-nova,
}:

let
  current = lib.trivial.importJSON ./version.json;

  srcMeta = {
    group = "garuda-linux";
    owner = "themes-and-settings/settings";
    repo = "garuda-dr460nized";
  };

  gitUrl = "https://gitlab.com/${srcMeta.group}/${srcMeta.owner}/${srcMeta.repo}.git";
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "dr460nized-kde-theme";
  inherit (current) version;

  src = fetchgit {
    url = gitUrl;
    inherit (current) rev;
    sha256 = current.hash;
  };

  malefor = fetchurl {
    url = "https://gitlab.com/garuda-linux/themes-and-settings/artwork/garuda-wallpapers/-/raw/master/src/garuda-wallpapers/Malefor.jpg";
    hash = "sha256-hlt3hyPKqn88JryyqegEglf8Tu8rkPv3iARPIuYYy2Q=";
  };

  buildInputs = [
    beautyline-icons
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
      --replace "applications:snapper-tools.desktop," "" \
      --replace ",applications:octopi.desktop" ""
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

    install -Dm644 $malefor \
      $out/share/wallpapers/garuda-wallpapers/Malefor.jpg

    runHook postInstall
  '';

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit (finalAttrs) pname;
    nyxKey = "dr460nized-kde-theme";
    versionPath = "pkgs/dr460nized-kde-theme/version.json";
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
