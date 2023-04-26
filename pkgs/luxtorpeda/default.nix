{ stdenv
, lib
, fetchurl
, writeScript
}:

stdenv.mkDerivation (finalAttrs: {
  name = "luxtorpeda";
  version = "63";

  src = fetchurl {
    url = "https://github.com/luxtorpeda-dev/luxtorpeda/releases/download/v${finalAttrs.version}/luxtorpeda-${finalAttrs.version}.tar.xz";
    sha256 = "sha256-aUJa9k/GolIN6lWBjdKyaK0yOhWOinmaGn/x8It8Mhg=";
  };

  buildCommand = ''
    mkdir -p $out/bin
    tar -C $out/bin --strip=1 -x -f $src
  '';

  meta = with lib; {
    description = "Steam Play compatibility tool to run games using native Linux engines";
    homepage = "https://github.com/luxtorpeda-dev/luxtorpeda";
    license = licenses.gpl2Plus;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ pedrohlc ];
  };
})
