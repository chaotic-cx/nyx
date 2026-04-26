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
  sqlite,
  wireguard-tools,
  writeShellScript,
}:

let
  current = lib.trivial.importJSON ./version.json;

  version = current.version;

  nordVPNBase = stdenv.mkDerivation {
    pname = "nordvpn-core";
    inherit version;

    src = fetchurl {
      url = "https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn/nordvpn_${version}_amd64.deb";
      hash = current.hash;
    };

    buildInputs = [
      libxml2_13
      libidn2
      libnl
      libcap_ng
      sqlite
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

  passthru.updateScript = writeShellScript "update-nordvpn" ''
      set -euo pipefail

      INDEX="https://repo.nordvpn.com/deb/nordvpn/debian/dists/stable/main/binary-amd64/Packages.gz"

      VERSION=$(
        curl -s "$INDEX" \
        | gunzip \
        | awk '/^Package: nordvpn$/{p=1} p&&/^Version:/{print $2; p=0}' \
        | sort -V \
        | tail -1
      )

      URL="https://repo.nordvpn.com/deb/nordvpn/debian/pool/main/n/nordvpn/nordvpn_''${VERSION}_amd64.deb"

      RAW=$(nix-prefetch-url "$URL")
      HASH=$(nix hash convert --to sri sha256:$RAW)

      cat > pkgs/nordvpn/version.json <<EOF
    {
      "version": "$VERSION",
      "hash": "$HASH"
    }
    EOF
  '';

  meta = with lib; {
    description = "CLI client for NordVPN";
    homepage = "https://www.nordvpn.com";
    license = licenses.unfreeRedistributable;
    maintainers = with maintainers; [ dr460nf1r3 ];
    platforms = [ "x86_64-linux" ];
  };
}
