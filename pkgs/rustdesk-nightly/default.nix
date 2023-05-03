{ lib
, fetchFromGitHub
, makeDesktopItem
, copyDesktopItems
, makeWrapper
, rustPlatform
, cmake
, yasm
, nasm
, pkg-config
, clang
, gtk3
, xdotool
, libxcb
, libXfixes
, alsa-lib
, pulseaudio
, libXtst
, libvpx
, libyuv
, libopus
, llvmPackages
, wrapGAppsHook
, writeText
, flutter
, python3
, gst_all_1
}:

rustPlatform.buildRustPackage rec {
  pname = "rustdesk";
  version = "unstable-2023-05-03";

  src = fetchFromGitHub {
    owner = "rustdesk";
    repo = "rustdesk";
    rev = "0ed209b4d2457642b0067ad6f0522fd46ddfe052";
    sha256 = "sha256-HbPM9EGlcPZffZQRRRs8HwtcnEFsh5+GDC/qxDhjmPw=";
  };

  LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "confy-0.4.0" = "sha256-e91cvEixhpPzIthAxzTa3fDY6eCsHUy/eZQAqs7QTDo=";
      "evdev-0.11.5" = "sha256-aoPmjGi/PftnH6ClEWXHvIj0X3oh15ZC1q7wPC1XPr0=";
      "hwcodec-0.1.0" = "sha256-SHJ+WjQ4o1eFXnMXFsudzs5XdfBpuAOwLv3BIrkhTuU=";
      "impersonate_system-0.1.0" = "sha256-qbaTw9gxMKDjX5pKdUrKlmIxCxWwb99YuWPDvD2A3kY=";
      "magnum-opus-0.4.0" = "sha256-NWYobxN2X18f0l8GmLB9dULm+GZD04mI03EvRy05K10=";
      "mouce-0.2.1" = "sha256-3PtNEmVMXgqKV4r3KiKTkk4oyCt4BKynniJREE+RyFk=";
      "pam-0.7.0" = "sha256-qe2GH6sfGEUnqLiQucYLB5rD/GyAaVtm9pAxWRb1H3Q=";
      "parity-tokio-ipc-0.7.3-1" = "sha256-eULJePtBu0iBI3It/bPH0h82Obsb1PJALgwYwrnCFYI=";
      "rdev-0.5.0-2" = "sha256-O1d3klGVnXhzb5rj2sH9u+z+iPmqVqkaHdxYiMiD+GA=";
      "rust-pulsectl-0.2.12" = "sha256-8jXTspWvjONFcvw9/Z8C43g4BuGZ3rsG32tvLMQbtbM=";
      "sciter-rs-0.5.57" = "sha256-ZZnZDhMjK0LjgmK0da1yvB0uoKueLhhhQtzmjoN+1R0=";
      "tao-0.18.1" = "sha256-fe9OcBZh/Vw2tGOv+GQq127Xml7CkISsB1kd3dUOFlA=";
      "tfc-0.6.1" = "sha256-ukxJl7Z+pUXCjvTsG5Q0RiXocPERWGsnAyh3SIWm0HU=";
      "tokio-socks-0.5.1-1" = "sha256-45QQ6FrhGU9uEhbKXTKd/mY6MDumO6p46NmlakdyDQk=";
      "trayicon-0.1.3-1" = "sha256-cCaH/DRIOP/uvGp+eqqq8xR92BU+oBfDne0y/eYa+QA=";
      "x11-2.19.0" = "sha256-GDCeKzUtvaLeBDmPQdyr499EjEfT6y4diBMzZVEptzc=";
    };
  };


  # Manually simulate a vcpkg installation so that it can link the libaries
  # properly.
  postUnpack =
    let
      vcpkg_target = "x64-linux";

      updates_vcpkg_file = writeText "update_vcpkg_rustdesk"
        ''
          Package : libyuv
          Architecture : ${vcpkg_target}
          Version : 1.0
          Status : is installed

          Package : libvpx
          Architecture : ${vcpkg_target}
          Version : 1.0
          Status : is installed
        '';
    in
    ''
      export VCPKG_ROOT="$TMP/vcpkg";

      mkdir -p $VCPKG_ROOT/.vcpkg-root
      mkdir -p $VCPKG_ROOT/installed/${vcpkg_target}/lib
      mkdir -p $VCPKG_ROOT/installed/vcpkg/updates
      ln -s ${updates_vcpkg_file} $VCPKG_ROOT/installed/vcpkg/status
      mkdir -p $VCPKG_ROOT/installed/vcpkg/info
      touch $VCPKG_ROOT/installed/vcpkg/info/libyuv_1.0_${vcpkg_target}.list
      touch $VCPKG_ROOT/installed/vcpkg/info/libvpx_1.0_${vcpkg_target}.list

      ln -s ${libvpx.out}/lib/* $VCPKG_ROOT/installed/${vcpkg_target}/lib/
      ln -s ${libyuv.out}/lib/* $VCPKG_ROOT/installed/${vcpkg_target}/lib/
    '';

  nativeBuildInputs = [ pkg-config cmake makeWrapper copyDesktopItems yasm nasm clang wrapGAppsHook python3 flutter ];
  buildInputs = [ gst_all_1.gst-plugins-base alsa-lib pulseaudio libXfixes libxcb xdotool gtk3 libvpx libopus libXtst libyuv ];

  # Checks require an active X display.
  doCheck = false;

  desktopItems = [
    (makeDesktopItem {
      name = "rustdesk";
      exec = meta.mainProgram;
      icon = "rustdesk";
      desktopName = "RustDesk";
      comment = meta.description;
      genericName = "Remote Desktop";
      categories = [ "Network" ];
    })
  ];

  postPatch = ''
    rm Cargo.lock
    ln -s ${./Cargo.lock} Cargo.lock
  '';

  # Add static ui resources and libsciter to same folder as binary so that it
  # can find them.
  postInstall = ''
    mkdir -p $out/{share/src,lib/rustdesk}

    # so needs to be next to the executable
    mv $out/bin/rustdesk $out/lib/rustdesk
    cp -pr 'flutter/build/linux/x64/release/bundle' "$out/usr/lib/"

    makeWrapper $out/lib/rustdesk/rustdesk $out/bin/rustdesk \
      --chdir "$out/share"

    cp -a $src/src/ui $out/share/src
    install -Dm0644 'res/32x32.png' "$out/usr/share/icons/hicolor/32x32/apps/rustdesk-nightly.png"
    install -Dm0644 'res/128x128.png' "$out/usr/share/icons/hicolor/128x128/apps/rustdesk-nightly.png"
    install -Dm0644 'res/128x128@2x.png' "$out/usr/share/icons/hicolor/256x256/apps/rustdesk-nightly.png"
  '';

  meta = with lib; {
    description = "Yet another remote desktop software";
    homepage = "https://rustdesk.com";
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ ocfox leixb ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "rustdesk";
  };
}
