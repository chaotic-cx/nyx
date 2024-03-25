{ fetchFromGitHub
, lib
, stdenvNoCC
}:
stdenvNoCC.mkDerivation rec {
  pname = "applet-window-title";
  version = "0.5";

  src = fetchFromGitHub {
    owner = "dhruv8sh";
    repo = "plasma6-window-title-applet";
    rev = "v${version}";
    hash = "sha256-p10sHXsuAgbeOaTAYysxnkOwz3Vlh6Bl8S5lGHMvads=";
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
    description = "Plasma 6 applet that shows the application title and icon for active window";
    homepage = "https://github.com/psifidotos/applet-window-title";
    license = licenses.gpl2Plus;
    maintainers = [ maintainers.dr460nf1r3 ];
    platforms = platforms.all;
  };
}
