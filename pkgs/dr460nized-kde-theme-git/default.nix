{ beautyline-icons-git
, dr460nized-kde-git-src
, lib
, stdenvNoCC
, sweet-nova
}:
stdenvNoCC.mkDerivation rec {
  pname = "dr460nized-kde-theme-git";
  version = "unstable-2023-04-02";

  src = dr460nized-kde-git-src;

  buildInputs = [ beautyline-icons-git sweet-nova ];

  installPhase = ''
    runHook preInstall
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
