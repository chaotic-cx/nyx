{ ananicy-cpp-rules-git-src
, lib
, nyxUtils
, stdenvNoCC
, ...
}:
let
  src = ananicy-cpp-rules-git-src;
in
stdenvNoCC.mkDerivation {
  pname = "ananicy-cpp-rules";

  inherit src;
  version = nyxUtils.gitToVersion src;

  installPhase = ''
    runHook preInstall
    install -d $out/etc/ananicy.d
    cp -r * $out/etc/ananicy.d
    rm $out/etc/ananicy.d/README.md
    runHook postInstall
  '';

  meta = with lib; {
    description = "CachyOS' ananicy-rules meant to be used with ananicy-cpp";
    homepage = "https://github.com/CachyOS/ananicy-rules";
    license = licenses.gpl3;
    maintainers = [ maintainers.dr460nf1r3 ];
    platforms = platforms.all;
  };

  updateScript = null;
}
