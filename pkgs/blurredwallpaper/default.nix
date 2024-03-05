{ fetchFromGitHub
, lib
, stdenvNoCC
}:
stdenvNoCC.mkDerivation rec {
  pname = "blurredwallpaper";
  version = "3.0.0";

  src = fetchFromGitHub {
    owner = "bouteillerAlan";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-mCqf03cXlTl4vuJIzVEiYhHQsAPG3i6yHQ3Xdt06HfA=";
  };

  propagatedBuildInputs = [ ];

  installPhase = ''
    runHook preInstall
    install -d $out/share/plasma/wallpapers/a2n.blur
    cp -r * $out/share/plasma/wallpapers/a2n.blur
    rm $out/share/plasma/wallpapers/a2n.blur/{AUTHORS,CHANGELOG,CODE_OF_CONDUCT.md,CONTRIBUTING.md,LICENSE,README.md,SECURITY.md}
    runHook postInstall
  '';

  meta = with lib; {
    description = "Plasma 6 wallpaper plugin that blurs the wallpaper when a window is active";
    homepage = "https://github.com/bouteillerAlan/blurredwallpaper";
    license = licenses.gpl3;
    maintainers = [ maintainers.dr460nf1r3 ];
    platforms = platforms.all;
  };
}
