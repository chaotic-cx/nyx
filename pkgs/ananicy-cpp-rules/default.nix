{ lib
, stdenvNoCC
, callPackage
, fetchFromGitHub
, ...
}:
let
  current = lib.trivial.importJSON ./version.json;
in
stdenvNoCC.mkDerivation rec {
  pname = "ananicy-cpp-rules";
  inherit (current) version;

  src = fetchFromGitHub {
    inherit (current) rev hash;
    owner = "CachyOS";
    repo = "ananicy-rules";
  };

  installPhase = ''
    runHook preInstall
    mkdir -p $out/etc/ananicy.d
    rm README.md LICENSE
    cp -r * $out/etc/ananicy.d
    runHook postInstall
  '';

  passthru.updateScript = callPackage ../../shared/git-update.nix {
    inherit pname;
    nyxKey = "ananicy-cpp-rules";
    versionPath = "pkgs/ananicy-cpp-rules/version.json";
    fetchLatestRev = callPackage ../../shared/github-rev-fetcher.nix { } "master" src;
    gitUrl = src.gitRepoUrl;
  };

  meta = with lib; {
    description = "CachyOS' ananicy-rules meant to be used with ananicy-cpp";
    homepage = "https://github.com/CachyOS/ananicy-rules";
    license = licenses.gpl3;
    maintainers = [ maintainers.dr460nf1r3 ];
    platforms = platforms.all;
  };
}
