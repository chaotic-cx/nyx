function join_by { # https://stackoverflow.com/a/17841619
  local d=${1-} f=${2-}
  if shift 2; then
    printf %s "$f" "${@/#/$d}"
  fi
}

function checkout() {
  git checkout -b "$NYX_BRANCH"
  #git fetch origin
  #git reset --hard origin/main
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

function bump-package() {
  echo "Bumping $1"

  _PREV=$(git rev-parse HEAD)

  for script in "${@:2}"; do
    $script || return 0
  done

  if [ "$_PREV" != $(git rev-parse HEAD) ]; then
    echo "Building $1"
    if ! (NYX_CHANGED_ONLY="git+file:$PWD?rev=$_PREV" \
        PHASES='prepare build-jobs no-fail' \
        nix develop --impure -c 'chaotic-nyx-build') \
        && nixReturn=$? && [ $nixReturn -eq 43 ]; then
      git revert --no-commit "${_PREV}..HEAD"
      git commit -m "Bumping \"$1\" failed"
    else
      echo "Exited with $nixReturn"
    fi
  fi

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

function deploy-cache() {
  nix develop -c 'chaotic-nyx-build' || [ $? -eq 42 ]
}
