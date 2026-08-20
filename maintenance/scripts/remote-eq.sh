#!/usr/bin/env bash
set -euo pipefail

BRANCH_NAME="${1:?Missing branch name}"
START_COMMIT="${2:-}"

if [ -n "$START_COMMIT" ]; then
  END_COMMIT="${3:-$(git rev-parse HEAD)}"

  if [ "$START_COMMIT" = "$END_COMMIT" ]; then
    echo "No changes commited. Avoiding!"

    exit 42
  fi
fi

if git ls-remote --exit-code --heads origin "$BRANCH_NAME" >/dev/null; then
  git fetch origin "$BRANCH_NAME"

  if git diff HEAD "origin/$BRANCH_NAME" --quiet; then
    echo "Same change is already pushed. Avoiding!"
    exit 42
  fi

  echo "Differences found. Proceeding"
else
  echo "Creating branch. Proceeding"
fi

exit 0
