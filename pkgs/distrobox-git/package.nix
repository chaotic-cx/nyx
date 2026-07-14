{ buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "distrobox";
  version = "unstable";
  src = fetchFromGitHub {
    owner = "89luca89";
    repo = "distrobox";
    rev = "4c334118a1334f1616e7c8d24e974c6bbf872d84";
    hash = "sha256-nNeQOvn3sNd8C0lhmzR7ygKwwh6jmdE1vxawoTfMQR0=";
  };
  vendorHash = "sha256-zGp+2bmvt/VCbM656YlRbDNpr2hpcVto+hqtm4Mv+gY=";
  subPackages = [ "cmd/distrobox" ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/share/man/man1
    mkdir -p $out/share/bash-completion/completions $out/share/zsh/site-functions
    mkdir -p $out/share/icons/hicolor/{scalable/apps,16x16/apps,22x22/apps,24x24/apps,32x32/apps,36x36/apps,48x48/apps,64x64/apps,72x72/apps,96x96/apps,128x128/apps,256x256/apps}

    install -m 0755 $GOPATH/bin/distrobox $out/bin/distrobox

    for sub in assemble create enter ephemeral generate-entry ls list rm stop upgrade; do
      ln -sf distrobox $out/bin/distrobox-$sub
    done

    install -m 0755 internal/inside-distrobox/assets/distrobox-init $out/bin/distrobox-init
    install -m 0755 internal/inside-distrobox/assets/distrobox-export $out/bin/distrobox-export
    install -m 0755 internal/inside-distrobox/assets/distrobox-host-exec $out/bin/distrobox-host-exec

    install -m 0644 man/man1/*.1 $out/share/man/man1/
    install -m 0644 completions/bash/distrobox $out/share/bash-completion/completions/distrobox
    install -m 0644 completions/zsh/_distrobox $out/share/zsh/site-functions/_distrobox

    install -m 0644 icons/terminal-distrobox-icon.svg $out/share/icons/hicolor/scalable/apps/
    for sz in 16 22 24 32 36 48 64 72 96 128 256; do
      install -m 0644 icons/hicolor/''${sz}x''${sz}/apps/terminal-distrobox-icon.png $out/share/icons/hicolor/''${sz}x''${sz}/apps/
    done

    runHook postInstall
  '';
}
