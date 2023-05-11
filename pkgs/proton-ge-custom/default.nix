{ stdenv
, lib
, fetchurl
, writeScript
, protonGeTitle ? null
, protonGeBase ? "8"
, protonGeRelease ? "3"
, protonGeHash ? "sha256-JYGwb0LhIs6B2/OHiU+mJ/dAAS+Dg+MrVksAsn6IS9g="
}:

stdenv.mkDerivation (finalAttrs: {
  name = "proton-ge-custom";
  version = "${protonGeBase}.${protonGeRelease}";

  src =
    let
      geVersion = "GE-Proton${protonGeBase}-${protonGeRelease}";
    in
    fetchurl {
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${geVersion}/${geVersion}.tar.gz";
      hash = protonGeHash;
    };

  buildCommand = ''
    mkdir -p $out/bin
    tar -C $out/bin --strip=1 -x -f $src
  ''
  # Allow to keep the same name between updates
  + lib.strings.optionalString (protonGeTitle != null) ''
    sed -i -r 's|"GE-Proton.*"|"${protonGeTitle}"|' $out/bin/compatibilitytool.vdf
  '';

  meta = with lib; {
    description = "Compatibility tool for Steam Play based on Wine and additional components";
    homepage = "https://github.com/GloriousEggroll/proton-ge-custom";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ pedrohlc shawn8901 ];
  };
})
