{ fetchFromGitHub
, lib
, stdenvNoCC
,
}:
stdenvNoCC.mkDerivation rec {
  pname = "applet-window-title";
  version = "0.7.1";

  src = fetchFromGitHub {
    owner = "psifidotos";
    repo = pname;
    rev = version;
    hash = "sha256-KybioiBzSxy15f9BD8CDlAuROygeUuYeQBsN4/UwxgY=";
  };

  propagatedBuildInputs = [ ];

  installPhase = ''
    runHook preInstall
    install -d $out/share/plasma/plasmoids/org.kde.windowtitle
    cp -r * $out/share/plasma/plasmoids/org.kde.windowtitle
    rm $out/share/plasma/plasmoids/org.kde.windowtitle/{CHANGELOG.md,LICENSE,README.md}
    runHook postInstall
  '';

  meta = with lib; {
    description = "Plasma 5 applet that shows the application title and icon for active window";
    homepage = "https://github.com/psifidotos/applet-window-title";
    license = licenses.gpl2Plus;
    maintainers = [ "dr460nf1r3" ];
    platforms = platforms.all;
  };
}
