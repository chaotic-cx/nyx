{ breeze-icons
, fetchFromGitLab
, gnome-icon-theme
, gtk3
, hicolor-icon-theme
, jdupes
, lib
, mint-x-icons
, pantheon
, stdenvNoCC
,
}:
stdenvNoCC.mkDerivation rec {
  pname = "BeautyLine";
  version = "unstable-2023-04-02";

  src = fetchFromGitLab {
    owner = "garuda-linux/themes-and-settings/artwork";
    repo = pname;
    rev = "24052efcb887a58721ffef731181af65ee81b3c1";
    sha256 = "sha256-6Nt7m/P0WUjoOetWLrh6pgkyg7FSLg1hGURgKgy6zdc=";
  };

  sourceRoot = "${src.name}";

  nativeBuildInputs = [ jdupes gtk3 ];

  # ubuntu-mono is also required but missing in ubuntu-themes (please add it if it is packaged at some point)
  propagatedBuildInputs = [
    breeze-icons
    gnome-icon-theme
    hicolor-icon-theme
    mint-x-icons
    pantheon.elementary-icon-theme
  ];

  dontDropIconThemeCache = true;

  dontPatchELF = true;
  dontRewriteSymlinks = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share/icons/${pname}
    cp -r * $out/share/icons/${pname}/
    rm -rf $out/share/icons/${pname}/{.gitignore,README.md,ReadMe}
    gtk-update-icon-cache $out/share/icons/${pname}
    jdupes --link-soft --recurse $out/share
    runHook postInstall
  '';

  meta = with lib; {
    description = "BeautyLine icon theme mixed with Sweet icons";
    homepage = "https://gitlab.com/garuda-linux/themes-and-settings/artwork/beautyline";
    license = lib.licenses.gpl3;
    maintainers = [ "dr460nf1r3" ];
    platforms = platforms.all;
  };
}
