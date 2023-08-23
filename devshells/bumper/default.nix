{ coreutils
, gnused
, ripgrep
, update-scripts
, writeShellScriptBin
}@p:
let
  git = "${p.git}/bin/git";
  nix = "${p.nix}/bin/nix";
  date = "${p.coreutils}/bin/date";
  grep = "${p.ripgrep}/bin/rg";
  sed = "${p.gnused}/bin/sed";
  gh = "${p.gh}/bin/gh";
in
writeShellScriptBin "chaotic-nyx-bumper" ''
  #!/usr/bin/env bash
  set -euo pipefail

  function join_by { # https://stackoverflow.com/a/17841619
    local d=''${1-} f=''${2-}
    if shift 2; then
      printf %s "$f" "''${@/#/$d}"
    fi
  }

  BUMPN=''${BUMPN:-1}
  NAME=''${NAME:-$(${date} '+%Y%m%d')-$BUMPN}
  BRANCH=''${BRANCH:-bump/$NAME}

  function checkout() {
    ${git} checkout -b "$BRANCH"
    ${git} fetch origin
    ${git} reset --hard origin/main
    return 0
  }

  function bump-flake() {
    ${nix} flake update
    CHANGED=()
    readarray -t CHANGED < <(${git} diff | ${grep} -Po '(?<=^     ")([^"]+)(?=": {$)' | ${sed} 's/-src$//;s/-git$//')
    [ -z "$CHANGED" ] && return 0
    CHANGED_CSV=$(join_by ', ' "''${CHANGED[@]}")
    ${git} add -u
    ${git} commit -m "flake-''${NAME}: $CHANGED_CSV"
    return 0
  }

  function bump-packages() {
    (${update-scripts}/bin/chaotic-nyx-update-scripts) || true
  }

  function push() {
    ${git} push origin "$BRANCH" -u
  }

  function create-pr() {
    ${gh} pr create -B main -H "$BRANCH" \
      --title "Bump $NAME" \
      --body 'Bump our packages since we do this daily.'
  }

  function default-phases () {
    checkout
    bump-flake
    bump-packages
    push
    create-pr
  }

  PHASES=''${PHASES:-default-phases};
  $PHASES
''
