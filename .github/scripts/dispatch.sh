#!/usr/bin/env bash
# Compares two JSON fingerprints and dispatches a SINGLE build job with ALL changed packages.
#
# Usage: ./dispatch.sh --base <old.json> --head <new.json> [options]
#
# Required:
#   --base           JSON fingerprint from BASE (e.g. origin/main)
#   --head           JSON fingerprint from HEAD (e.g. PR branch)
#
# Optional:
#   --repo           Target repo (default: lonerOrz/nyx-loner)
#   --pr             PR number (required by downstream workflow)
#   --dry-run        Print payload without sending
#   --ref            Target branch for the workflow (default: main)

set -euo pipefail

BASE_FILE=""
HEAD_FILE=""
REPO="lonerOrz/nyx-loner"
PR=""
WORKFLOW_REPO="lonerOrz/nixpkgs-review-gha"
WORKFLOW_FILE="build-pr.yml"
REF="main"
DRY_RUN=0

usage() {
  cat <<EOF
Usage: $0 --base <old.json> --head <new.json> [options]

Required:
  --base           Path to baseline JSON (before changes)
  --head           Path to current JSON (after changes)

Optional:
  --repo           Target repo (default: lonerOrz/nyx-loner)
  --pr             PR number (REQUIRED by downstream workflow)
  --dry-run        Print payload without sending
  --ref            Branch to dispatch (default: main)

Env:
  GH_TOKEN         GitHub token (required)
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) BASE_FILE="$2"; shift 2 ;;
    --head) HEAD_FILE="$2"; shift 2 ;;
    --repo) REPO="$2"; shift 2 ;;
    --pr) PR="$2"; shift 2 ;;
    --dry-run) DRY_RUN=1; shift ;;
    --ref) REF="$2"; shift 2 ;;
    *) usage ;;
  esac
done

# -----------------------------
# Validate inputs
# -----------------------------
[[ -z "$BASE_FILE" || -z "$HEAD_FILE" ]] && usage
[[ -z "$PR" ]] && { echo "Error: --pr is required" >&2; exit 1; }

AUTH_TOKEN="${GH_TOKEN:-${GITHUB_TOKEN:-}}"
[[ -z "$AUTH_TOKEN" ]] && { echo "Error: GH_TOKEN or GITHUB_TOKEN is required" >&2; exit 1; }

[[ ! -f "$BASE_FILE" || ! -f "$HEAD_FILE" ]] && {
  echo "Error: Input files not found"
  exit 1
}

# -----------------------------
# 1. Calculate Diff & Deduplicate
# -----------------------------
# If multiple packages map to the same drvPath (e.g. mesa_git, mesa32_git),
# we only dispatch one build to avoid redundancy.
CHANGED_PKGS_RAW=$(jq -r -n \
  --slurpfile base "$BASE_FILE" \
  --slurpfile head "$HEAD_FILE" '
  ($base[0]) as $b |
  $head[0]
  | to_entries
  | map(select(.value != null))                      # avoid null drvPath issues
  | map(select(.value != ($b[.key] // null)))
  | sort_by(.value)                                  # REQUIRED before group_by
  | group_by(.value)
  | map(.[0].key)
  | sort[]
')

if [[ -z "$CHANGED_PKGS_RAW" ]]; then
  echo "No changes detected."
  exit 0
fi

# Safe conversion to array (avoids word splitting)
mapfile -t CHANGED_PKGS <<< "$CHANGED_PKGS_RAW"

# -----------------------------
# 2. Filter Policy
# -----------------------------
EXCLUDES=(
  '_v(2|3|4)$'     # Microarch variants
  '^firefox'       # Firefox family
  '^linux(_|$)'    # Linux kernel family
)

should_build() {
  local pkg="$1"
  for pattern in "${EXCLUDES[@]}"; do
    if [[ "$pkg" =~ $pattern ]]; then return 1; fi
  done
  return 0
}

VALID_PKGS=()
for pkg in "${CHANGED_PKGS[@]}"; do
  if should_build "$pkg"; then
    VALID_PKGS+=("$pkg")
  else
    echo "✗ Skip $pkg"
  fi
done

if [[ ${#VALID_PKGS[@]} -eq 0 ]]; then
  echo "No packages to dispatch after filtering."
  exit 0
fi

echo "Packages to dispatch:"
printf "→ %s\n" "${VALID_PKGS[@]}"
echo ""

# -----------------------------
# 3. Single Dispatch (All Packages as Matrix)
# -----------------------------
echo "→ Dispatching: ${VALID_PKGS[*]}"

# cleanup temp file on exit
cleanup() {
  [[ -n "${RESPONSE:-}" && -f "$RESPONSE" ]] && rm -f "$RESPONSE"
}
trap cleanup EXIT

# Comma-separated for GitHub workflow input
DISPATCH_URL="https://api.github.com/repos/${WORKFLOW_REPO}/actions/workflows/${WORKFLOW_FILE}/dispatches"
PACKAGES_CSV=$(IFS=','; echo "${VALID_PKGS[*]}")

# CRITICAL: inputs values MUST be strings
payload=$(jq -n \
  --arg repo "$REPO" \
  --arg pr "$PR" \
  --arg pkgs "$PACKAGES_CSV" \
  --arg ref "$REF" \
  '{
    ref: $ref,
    inputs: {
      repo: $repo,
      "pr-number": $pr,
      packages: $pkgs,
      "post-result": "true",
      "upload-cachix": "false",
      "x86_64-linux": "true",
      "aarch64-linux": "false",
      "x86_64-darwin": "no",
      "aarch64-darwin": "no"
    }
  }')

if [[ "$DRY_RUN" -eq 1 ]]; then
  echo "$payload" | jq .
  exit 0
fi

RESPONSE=$(mktemp)

# simple retry (handles transient GitHub API / network issues)
for attempt in 1 2 3; do
  status=$(curl -s -o "$RESPONSE" -w "%{http_code}" -X POST \
    -H "Accept: application/vnd.github+json" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -H "Content-Type: application/json" \
    "$DISPATCH_URL" \
    -d "$payload")

  if [[ "$status" -eq 204 ]]; then
    echo "✅ Dispatched ${#VALID_PKGS[@]} package(s) successfully"
    exit 0
  fi

  echo "❌ Failed (HTTP $status) [attempt $attempt]" >&2
  cat "$RESPONSE" >&2

  if [[ "$attempt" -lt 3 ]]; then
    sleep $((attempt * 2))
  fi
done

echo "❌ All retries exhausted" >&2
exit 1
