{ lib
, coreutils
, gh
, git
, gnused
, nix
, ripgrep
, update-scripts
, writeShellScriptBin
}:
let
  path = lib.makeBinPath [
    coreutils
    git
    nix
    ripgrep
    gnused
    gh
  ];
in
writeShellScriptBin "chaotic-nyx-bumper" ''
  #!/usr/bin/env bash
  set -euo pipefail

  # Cleanup PATH for reproducibility.
  PATH="${path}"

  # All the required functions
  source ${./lib.sh}

  # Local stuff
  NYX_BUMPN=''${NYX_BUMPN:-1}
  NYX_NAME=''${NYX_NAME:-$(date '+%Y%m%d')-$NYX_BUMPN}
  NYX_BRANCH=''${NYX_BRANCH:-bump/$NYX_NAME}

  function bump-packages() {
    (${update-scripts}/bin/chaotic-nyx-update-scripts) || true
  }

  function default-phases () {
    checkout
    bump-flake
    bump-packages
    push
    create-pr
  }

  PHASES=''${PHASES:-default-phases};
  for phase in $PHASES; do $phase; done
''
