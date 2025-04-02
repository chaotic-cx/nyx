{
  beautyline-icons,
  callPackage,
  fetchFromGitLab,
  fetchurl,
  lib,
  plasma-plugin-blurredwallpaper,
  stdenvNoCC,
  sweet-nova,
}:

let
  current = lib.trivial.importJSON ./version.json;
  srcMeta = {
    inherit (current) rev hash;
    group = "garuda-linux";
    owner = "themes-and-settings/settings";
    repo = "garuda-dr460nized";
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "dr460nized-kde-theme";
  inherit (current) version;

  src = fetchFromGitLab srcMeta;

  malefor = fetchurl {
    url = "https://gitlab.com/garuda-linux/themes-and-settings/artwork/garuda-wallpapers/-/raw/master/src/garuda-wallpapers/Malefor.jpg";
    hash = "sha256-hlt3hyPKqn88JryyqegEglf8Tu8rkPv3iARPIuYYy2Q=";
  };

  buildInputs = [
    beautyline-icons
    plasma-plugin-blurredwallpaper
    sweet-nova
  ];

  installPhase = ''
    runHook preInstall
    install -d $out/skel
    cp -r etc/skel $out/
    install -d $out/share
    cp -r usr/share/* $out/share/
    install -Dm644 $malefor $out/share/wallpapers/garuda-wallpapers/Malefor.jpg
    runHook postInstall
  '';
  postPatch = ''
    for file in $(find ./* \( -type f \( -name "*.profile" -o -name "*.conf" -o ! -name "*.*" \) \) -o -type l ); do
      if [ -h $file ]; then
        ln -fs $(readlink $file | sed -e 's|/usr/share|/run/current-system/sw/share|g') $file
      else
        substituteInPlace $file --replace "/usr/bin" "/run/current-system/sw/bin" --replace "/usr/share" "/run/current-system/sw/share"
      fi
    done

    substituteInPlace usr/share/plasma/{look-and-feel/Dr460nized/contents/layouts/org.kde.plasma.desktop-layout.js,layout-templates/org.garuda.desktop.defaultDock/contents/layout.js} \
      --replace "applications:garuda-welcome.desktop," "" \
      --replace "applications:snapper-tools.desktop," "" \
      --replace ",applications:octopi.desktop" ""
  '';

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit pname;
    nyxKey = "dr460nized-kde-theme";
    versionPath = "pkgs/dr460nized-kde-theme/version.json";
    fetchLatestRev = callPackage ../../shared/gitlab-rev-fetcher.nix { } "main" srcMeta;
    gitUrl = src.gitRepoUrl;
  };

  meta = with lib; {
    description = "The default Garuda dr460nized theme";
    homepage = "https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-dr460nized";
    license = licenses.gpl3Only;
    maintainers = [ maintainers.dr460nf1r3 ];
    platforms = platforms.linux;
  };
}
