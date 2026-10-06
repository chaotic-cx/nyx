{
  lib,
  coreutils,
  curl,
  git,
  jq,
  nix,
  writeShellScript,
}:

let
  path = lib.makeBinPath [
    coreutils
    curl
    git
    jq
    nix
  ];
in
writeShellScript "firefox-nightly-update" (
  ''
    export PATH="${path}:''${PATH}"
  ''
  + builtins.readFile ./update.sh
)
