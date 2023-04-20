# The smallest and KISSer continuos-deploy I was able to create.
{ all-packages
, cachix
, derivationRecursiveFinder
, flakeSelf
, jq
, lib
, nix
, writeShellScriptBin
}:
let
  evalCommand = key: drv:
    let
      derivation = "$NYX_SOURCE#${key}";
      fullTag = output: "\"${derivationRecursiveFinder.join derivation output}\"";
      outputs = map fullTag drv.outputs;
    in
    ''
      build "${key}" "${builtins.unsafeDiscardStringContext drv.outPath}" \
        ${lib.strings.concatStringsSep " \\\n  " outputs}
    '';

  packagesEval = derivationRecursiveFinder.evalToString evalCommand all-packages;
in
writeShellScriptBin "build-chaotic-nyx" ''
  NYX_SOURCE="''${NYX_SOURCE:-${flakeSelf}}"
  NYX_FLAGS="''${NYX_FLAGS:---accept-flake-config}"
  NYX_WD="''${NYX_WD:-$(mktemp -d)}"
  NYX_UNCACHED_ONLY="''${NYX_UNCACHED_ONLY:-0}"
  R='\033[0;31m'
  G='\033[0;32m'
  Y='\033[1;33m'
  W='\033[0m'

  cd "$NYX_WD"
  echo -n "" > push.txt > errors.txt > success.txt > failures.txt

  function echo_warning() {
    echo -ne "''${Y}WARNING:''${W} "
    echo "$@"
  }

  function echo_error() {
    echo -ne "''${R}ERROR:''${W} " 1>&2
    echo "$@" 1>&2
  }

  if [ -z "$CACHIX_AUTH_TOKEN" ] && [ -z "$CACHIX_SIGNING_KEY" ]; then
    echo_warning "No key for cachix -- building anyway."
  fi

  # Check if $1 is in the cache
  function cached() {
    set -e
    ${nix}/bin/nix path-info "$1" --store 'https://chaotic-nyx.cachix.org' >/dev/null 2>/dev/null
  }

  function build() {
    _WHAT="''${1:- アンノーン}"
    _DEST="''${2:-/dev/null}"
    echo -n "Building $_WHAT..."
    if cached "$_DEST"; then
      echo "$_WHAT" >> cached.txt
      echo -e "''${Y} CACHED''${W}"
    elif \
      ( set -o pipefail;
        ${nix}/bin/nix build --json $NYX_FLAGS "''${@:3}" |\
          ${jq}/bin/jq -r '.[].outputs[]' \
      ) 2>> errors.txt >> push.txt
    then
      echo "$_WHAT" >> success.txt
      echo -e "''${G} OK''${W}"
    else
      echo "$_WHAT" >> failures.txt
      echo -e "''${R} ERR''${W}"
    fi
  }

  ${packagesEval}

  if [ -z "$CACHIX_AUTH_TOKEN" ] && [ -z "$CACHIX_SIGNING_KEY" ]; then
    echo_error "No key for cachix -- failing to deploy."
    exit 23
  elif [ -s push.txt ]; then
    # Let nix digest store paths first
    sleep 10

    echo "Pushing to cache..."
    cat push.txt | ${cachix}/bin/cachix push chaotic-nyx \
      --compression-method zstd

  else
    echo_error "Nothing to push."
    exit 42
  fi

  exit 0
''
