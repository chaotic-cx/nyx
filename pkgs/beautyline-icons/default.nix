{ fetchFromGitLab
, gnome-icon-theme
, gtk3
, hicolor-icon-theme
, jdupes
, lib
, stdenvNoCC
}:
stdenvNoCC.mkDerivation rec {
  pname = "BeautyLine";
  version = "unstable-2023-06-03";

  src = fetchFromGitLab {
    owner = "garuda-linux/themes-and-settings/artwork";
    repo = pname;
    rev = "6ed423161e252d597ca7180bf16ce3d8c38e8af1";
    hash = "sha256-v4gAWBckba6s/ZHKNhLkho9WM8ylGmLxkVjX3Y7QEJE=";
  };

  nativeBuildInputs = [ jdupes gtk3 ];

  propagatedBuildInputs = [
    gnome-icon-theme
    hicolor-icon-theme
  ];

  dontDropIconThemeCache = true;

  dontPatchELF = true;
  dontRewriteSymlinks = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/icons/${pname}
    cp -r * $out/share/icons/${pname}/
    rm $out/share/icons/${pname}/{README.md,ReadMe}
    gtk-update-icon-cache $out/share/icons/${pname}
    jdupes --link-soft --recurse $out/share
    runHook postInstall
  '';

  meta = with lib; {
    description = "BeautyLine icon theme mixed with Sweet icons";
    homepage = "https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline";
    license = lib.licenses.gpl3;
    maintainers = [ maintainers.dr460nf1r3 ];
    platforms = platforms.all;
  };
}
