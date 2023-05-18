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
  version = "unstable-2023-05-18";

  src = fetchFromGitLab {
    owner = "garuda-linux/themes-and-settings/artwork";
    repo = pname;
    rev = "76864a0e4190ad82b8f66e4ccc45b9f5002597b8";
    hash = "sha256-/PK6S32W8kIW753vqMu8ky55i6xiCimX+1UPuju3WjQ=";
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
