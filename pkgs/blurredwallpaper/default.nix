{ fetchFromGitHub
, lib
, stdenvNoCC
}:
stdenvNoCC.mkDerivation rec {
  pname = "blurredwallpaper";
  version = "3.1.0";

  src = fetchFromGitHub {
    owner = "bouteillerAlan";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-+MjnVsGHqitQytxiAH39Kx9SXuTEFfIC14Ayzu4yE4I=";
  };

  propagatedBuildInputs = [ ];

  installPhase = ''
    runHook preInstall
    install -d $out/share/plasma/wallpapers/a2n.blur{,.plasma5}
    cp -r a2n.blur{,.plasma5} $out/share/plasma/wallpapers/
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
