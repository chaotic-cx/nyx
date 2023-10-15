function join_by { # https://stackoverflow.com/a/17841619
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

function checkout() {
  git checkout -b "$NYX_BRANCH"
  git fetch origin
  git reset --hard origin/main
  return 0
}

function bump-flake() {
  local CHANGED=() CHANGED_CSV
  nix flake update
  readarray -t CHANGED < <(git diff | rg -Po '(?<=^     ")([^"]+)(?=": {$)' | sed 's/-src$//;s/-git$//')
  [[ "${#CHANGED[@]}" -lt 1 ]] && return 0
  CHANGED_CSV=$(join_by ', ' "${CHANGED[@]}")
  git add -u
  git commit -m "flake-${NYX_NAME}: $CHANGED_CSV"
  return 0
}

function push() {
  git push origin "$NYX_BRANCH" -u
}

function create-pr() {
  gh pr create -B main -H "$NYX_BRANCH" \
    --title "Bump $NYX_NAME" \
    --body 'Bump our packages since we do this daily.'
}
