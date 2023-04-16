{ fetchFromGitHub
, lib
, stdenvNoCC
}:
stdenvNoCC.mkDerivation {
  pname = "ananicy-cpp-rules";
  version = "unstable-2023-03-31";

  src = fetchFromGitHub {
    owner = "CachyOS";
    repo = "ananicy-rules";
    rev = "973c537e7b7e89e8ce8e699e5a8c651c0fc778fa";
    hash = "sha256-qOMi9QXgs9QUocquzozrAFuuW/UZ3qp3VOgw0a2fx34=";
  };

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
