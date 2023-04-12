{ ananicy-rules-git-src
, lib
, stdenvNoCC
,
}:
stdenvNoCC.mkDerivation {
  pname = "ananicy-cpp-rules";
  version = "unstable-2023-03-31";

  src = ananicy-rules-git-src;

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
}
