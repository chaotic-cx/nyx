{ callPackage
, stdenv
, lib
, fetchurl
, writeScript
, luxtorpedaVersion
}:

stdenv.mkDerivation {
  name = "luxtorpeda";
  inherit (luxtorpedaVersion) version;

  src = fetchurl {
    inherit (luxtorpedaVersion) url hash;
  };

  buildCommand = ''
    mkdir -p $out/bin
    tar -C $out/bin --strip=1 -x -f $src
  '';

  passthru.updateScript = callPackage ./update.nix { };

  meta = with lib; {
    description = "Steam Play compatibility tool to run games using native Linux engines";
    homepage = "https://github.com/luxtorpeda-dev/luxtorpeda";
    changelog = "https://github.com/luxtorpeda-dev/luxtorpeda/releases/tag/v${luxtorpedaVersion.version}";
    license = licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ pedrohlc ];
  };
}
