{
  autoPatchelfHook,
  buildFHSEnvChroot,
  dpkg,
  fetchurl,
  lib,
  stdenv,
  sysctl,
  iptables,
  iproute2,
  procps,
  cacert,
  libxml2_13,
  libidn2,
  libnl,
  libcap_ng,
  wireguard-tools,
}:

let
  version = "3.20.2";

  nordVPNBase = stdenv.mkDerivation {
    pname = "nordvpn-core";
    inherit version;

    src = fetchurl {
      url = "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn/nordvpn_${version}_amd64.deb";
      hash = "sha256-2eLVr0aQpMhIMCrkyIRcCabXc197GJZ31Vl5BND7Di8=";
    };

    buildInputs = [
      libxml2_13
      libidn2
      libnl
      libcap_ng
    ];

    nativeBuildInputs = [
      dpkg
      autoPatchelfHook
      stdenv.cc.cc.lib
    ];

    dontConfigure = true;
    dontBuild = true;

    unpackPhase = ''
      runHook preUnpack
      dpkg --extract $src .
      runHook postUnpack
    '';

    installPhase = ''
      runHook preInstall
      mkdir -p $out
      mv usr/* $out/
      mv var/ $out/
      mv etc/ $out/
      runHook postInstall
    '';
  };

  nordVPNfhs = buildFHSEnvChroot {
    name = "nordvpnd";
    runScript = "nordvpnd";

    # hardcoded path to /sbin/ip
    targetPkgs =
      pkgs: with pkgs; [
        nordVPNBase
        sysctl
        iptables
        iproute2
        procps
        cacert
        wireguard-tools
      ];
  };
in
stdenv.mkDerivation {
  pname = "nordvpn";
  inherit version;

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/share
    ln -s ${nordVPNBase}/bin/nordvpn $out/bin
    ln -s ${nordVPNfhs}/bin/nordvpnd $out/bin
    ln -s ${nordVPNBase}/share/* $out/share/
    ln -s ${nordVPNBase}/var $out/
    runHook postInstall
  '';

  meta = with lib; {
    description = "CLI client for NordVPN";
    homepage = "https://www.nordvpn.com";
    license = licenses.unfreeRedistributable;
    maintainers = with maintainers; [ dr460nf1r3 ];
    platforms = [ "x86_64-linux" ];
  };
}
