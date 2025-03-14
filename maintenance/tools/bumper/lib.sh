function checkout() {
  git checkout -b "$NYX_BRANCH"
  git fetch origin
  git reset --hard origin/main
  return 0
}

function bump-flake() {
  nix flake update
  if git diff --quiet --exit-code; then
    return 0;
  elif [ $? -eq 1 ]; then
    echo 1;
    git add flake.lock
    git commit -m "flake: bump ${NYX_NAME}"
    return 0
  fi
}

function bump-package() {
  echo "# Bumping $1"

  _PREV=$(git rev-parse HEAD)

  for script in "${@:2}"; do
    $script || return 0
  done

  if [ "${NYX_BUMP_REVERT:-1}" != '0' ]; then
    _CURR=$(git rev-parse HEAD)
    if [ "$_PREV" != "$_CURR" ]; then
      echo "# Building $1"
      if NYX_CHANGED_ONLY="git+file:$PWD?rev=$_PREV" \
          PHASES='prepare build-jobs no-fail' \
          nix develop --impure ./maintenance -c 'chaotic-nyx-build'; \
      then return 0
      elif [ $? -eq 43 ]; then
        echo "## Failed, reverting ${_PREV}..${_CURR}"
        git revert --no-commit "${_PREV}..${_CURR}"
        git commit -m "Revert bumping \"$1\" (failed to build)"
      else
        echo "## Exited with $?"
      fi
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
