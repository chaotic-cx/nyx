{ stdenv
, lib
, fetchurl
, writeScript
,
}:
stdenv.mkDerivation (finalAttrs: {
  name = "proton-ge-custom";
  version = "GE-Proton7-55";

  src = fetchurl {
    url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${finalAttrs.version}/${finalAttrs.version}.tar.gz";
    sha256 = "sha256-/70DtApcja+6U+Rb1lUcEyUSrW/LqRIOJfDVENDNBIU=";
  };

  passthru.runUpdate = true;

  buildCommand = ''
    mkdir -p $out/bin
    tar -C $out/bin --strip=1 -x -f $src
  '';

  meta = with lib; {
    description = "Compatibility tool for Steam Play based on Wine and additional components";
    homepage = "https://github.com/GloriousEggroll/proton-ge-custom";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ ajs124 ];
  };
})
