{
  flakeSelf,
  nixpkgs,
  lib,
  coreutils,
  gh,
  git,
  nix,
  openssh,
  writeShellScriptBin,
  allPackages,
  nyxRecursionHelper,
}:
let
  inherit (lib.strings) concatStringsSep escapeShellArg;
  inherit (lib.lists) flatten;

  path = lib.makeBinPath [
    coreutils
    git
    nix
    gh
    openssh
  ];

  evalResult =
    k: v:
    if ((v.updateScript or null) != null) then
      "bump-package ${escapeShellArg k} "
      + (
        if (builtins.isList v.updateScript) then
          concatStringsSep " " (map escapeShellArg v.updateScript)
        else
          escapeShellArg v.updateScript
      )
    else
      null;

  skip =
    _k: _v: _message:
    null;

  packagesEval = nyxRecursionHelper.derivationsLimited 2 skip evalResult allPackages;

  packagesEvalSorted = builtins.filter (x: x != null) (flatten packagesEval);
in
writeShellScriptBin "chaotic-nyx-bumper" ''
  #!/usr/bin/env bash
  set -euo pipefail

  # Cleanup PATHs for reproducibility.
  PATH="${path}"
  NIX_PATH="chaotic=${flakeSelf}:nixpkgs=${nixpkgs}"

  # All the required functions
  source ${./lib.sh}

  # Local stuff
  NYX_BUMPN=''${NYX_BUMPN:-1}
  NYX_NAME=''${NYX_NAME:-$(date '+%Y%m%d')-$NYX_BUMPN}
  NYX_BRANCH=''${NYX_BRANCH:-bump/$NYX_NAME}

  function bump-packages() {
    ${concatStringsSep "\n  " packagesEvalSorted}
  }

  function default-phases () {
    checkout
    bump-packages
    bump-flake
    push
    create-pr
  }

  PHASES=''${PHASES:-default-phases};
  for phase in $PHASES; do $phase; done
''
