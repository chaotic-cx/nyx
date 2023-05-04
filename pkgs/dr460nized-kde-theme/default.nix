{ beautyline-icons
, fetchFromGitLab
, lib
, stdenvNoCC
, sweet-nova
}:
stdenvNoCC.mkDerivation rec {
  pname = "dr460nized-kde-theme";
  version = "unstable-2023-04-02";

  src = fetchFromGitLab {
    owner = "garuda-linux/themes-and-settings/settings";
    repo = "garuda-dr460nized";
    rev = "50dfcb081d3bc304ab16e98e2dd8168b11a9e017";
    sha256 = "sha256-73QxPtfoCGaV2g6A/IeKebakKLcyRMcX1WQnVGPTTAA=";
  };

  buildInputs = [ beautyline-icons sweet-nova ];

  installPhase = ''
    runHook preInstall
    install -d $out/skel
    cp -r etc/skel $out/
    install -d $out/share
    cp -r usr/share/plasma $out/share/
    install -d $out/share/icons/dr460nized
    cp -r usr/share/icons/garuda/* $out/share/icons/dr460nized
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
