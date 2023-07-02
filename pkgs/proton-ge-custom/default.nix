{ callPackage
, stdenv
, lib
, fetchurl
, writeScript
, protonGeTitle ? null
, protonGeVersions
}:

stdenv.mkDerivation (finalAttrs: {
  name = "proton-ge-custom";
  version = "${protonGeVersions.base}.${protonGeVersions.release}";

  src =
    let
      geVersion = "GE-Proton${protonGeVersions.base}-${protonGeVersions.release}";
    in
    fetchurl {
      url = "https://github.com/GloriousEggroll/proton-ge-custom/releases/download/${geVersion}/${geVersion}.tar.gz";
      inherit (protonGeVersions) hash;
    };

  buildCommand = ''
    mkdir -p $out/bin
    tar -C $out/bin --strip=1 -x -f $src
  ''
  # Allow to keep the same name between updates
  + lib.strings.optionalString (protonGeTitle != null) ''
    sed -i -r 's|"GE-Proton.*"|"${protonGeTitle}"|' $out/bin/compatibilitytool.vdf
  '';

  passthru.updateScript = callPackage ./update.nix { };

  meta = with lib; {
    description = "Compatibility tool for Steam Play based on Wine and additional components";
    homepage = "https://github.com/GloriousEggroll/proton-ge-custom";
    license = licenses.bsd3;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ pedrohlc shawn8901 ];
  };
})
