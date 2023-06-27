#!/usr/bin/env bash
set -euo pipefail

function join_by { # https://stackoverflow.com/a/17841619
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

NAME=${NAME:-$(date '+%Y%m%d')-${BN:-1}}
BRANCH=${BRANCH:-bump/$NAME}

function checkout() {
  git checkout -b "$BRANCH"
  git fetch origin
  git reset --hard origin/main
}

function bump-flake() {
  nix flake update
  CHANGED=()
  readarray -t CHANGED < <(git diff | grep -Po '(?<=^     ")([^"]+)(?=": {$)' | sed 's/-src$//;s/-git$//')
  CHANGED_CSV=$(join_by ', ' "${CHANGED[@]}")
  git add -u
  git commit -m "flake-${NAME}: $CHANGED_CSV"
}

function push() {
  git push origin "$BRANCH" -u
}

function build() {
  NYX_WD=${NYX_WD:-/tmp/bump-$NAME}
  mkdir -p "$NYX_WD"
  nix develop . -c build-chaotic-nyx
}

PHASES=${PHASES:-checkout && bump-flake && push && build};
$PHASES
