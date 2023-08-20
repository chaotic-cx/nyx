{ beautyline-icons-git-src
, gnome-icon-theme
, gtk3
, hicolor-icon-theme
, jdupes
, lib
, nyxUtils
, stdenvNoCC
, ...
}:

stdenvNoCC.mkDerivation rec {
  pname = "beautyline-icons";

  src = beautyline-icons-git-src;
  version = nyxUtils.gitToVersion src;

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
    license = licenses.gpl3;
    maintainers = [ maintainers.dr460nf1r3 ];
    platforms = platforms.all;
  };

  updateScript = null;
}
