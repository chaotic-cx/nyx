{ beautyline-icons
, fetchFromGitLab
, lib
, stdenvNoCC
, sweet-nova
}:
let
  wallpaper = builtins.fetchurl {
    url = "https://gitlab.com/garuda-linux/themes-and-settings/artwork/garuda-wallpapers/-/raw/master/src/garuda-wallpapers/Malefor.jpg";
    sha256 = "0r6b33k24kq4i3vzp41bxx7gqmw20klakcmw4qy7zana4f3pfnw6";
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "dr460nized-kde-theme";
  version = "unstable-2023-05-05";

  src = fetchFromGitLab {
    owner = "garuda-linux/themes-and-settings/settings";
    repo = "garuda-dr460nized";
    rev = "50dfcb081d3bc304ab16e98e2dd8168b11a9e017";
    sha256 = "sha256-73QxPtfoCGaV2g6A/IeKebakKLcyRMcX1WQnVGPTTAA=";
  };

  buildInputs = [ beautyline-icons sweet-nova ];

  installPhase = ''
    runHook preInstall
    install -d $out/{share,share/wallpapers/garuda,skel}
    cp -r etc/skel $out/
    cp -r usr/share/plasma $out/share/
    cp -r usr/share/icons $out/share/
    cp ${wallpaper} $out/share/wallpapers/garuda/Malefor.jpg
    runHook postInstall
  '';

  meta = with lib; {
    description = "The default Garuda dr460nized theme";
    homepage = "https://gitlab.com/garuda-linux/themes-and-settings/settings/garuda-dr460nized";
    license = licenses.gpl3Only;
    maintainers = [ "dr460nf1r3" ];
    platforms = platforms.all;
  };
}
