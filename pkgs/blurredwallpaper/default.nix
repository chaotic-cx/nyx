{ fetchFromGitHub
, lib
, stdenvNoCC
}:
stdenvNoCC.mkDerivation rec {
  pname = "blurredwallpaper";
  version = "v2.2";

  src = fetchFromGitHub {
    owner = "bouteillerAlan";
    repo = pname;
    rev = version;
    hash = "sha256-FgEyKVNTSJklYo/B4p0BqK9eYoc/3DU4nDxYdElDyCw=";
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
    description = "Plasma 5 applet that shows the application title and icon for active window";
    homepage = "https://github.com/psifidotos/applet-window-title";
    license = licenses.gpl2Plus;
    maintainers = [ maintainers.dr460nf1r3 ];
    platforms = platforms.all;
  };
}
