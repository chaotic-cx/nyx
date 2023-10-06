{ coreutils
, gh
, git
, gnused
, nix
, ripgrep
, update-scripts
, writeShellScriptBin
}:
let
  Git = "${git}/bin/git";
  Nix = "${nix}/bin/nix";
  Date = "${coreutils}/bin/date";
  Grep = "${ripgrep}/bin/rg";
  Sed = "${gnused}/bin/sed";
  Gh = "${gh}/bin/gh";
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
  NAME=''${NAME:-$(${Date} '+%Y%m%d')-$BUMPN}
  BRANCH=''${BRANCH:-bump/$NAME}

  function checkout() {
    ${Git} checkout -b "$BRANCH"
    ${Git} fetch origin
    ${Git} reset --hard origin/main
    return 0
  }

  function bump-flake() {
    ${Nix} flake update
    CHANGED=()
    readarray -t CHANGED < <(${Git} diff | ${Grep} -Po '(?<=^     ")([^"]+)(?=": {$)' | ${Sed} 's/-src$//;s/-git$//')
    [[ "''${#CHANGED[@]}" -lt 1 ]] && return 0
    CHANGED_CSV=$(join_by ', ' "''${CHANGED[@]}")
    ${Git} add -u
    ${Git} commit -m "flake-''${NAME}: $CHANGED_CSV"
    return 0
  }

  function bump-packages() {
    (${update-scripts}/bin/chaotic-nyx-update-scripts) || true
  }

  function push() {
    ${Git} push origin "$BRANCH" -u
  }

  function create-pr() {
    ${Gh} pr create -B main -H "$BRANCH" \
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
  for phase in $PHASES; do $phase; done
''
