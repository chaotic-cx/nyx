# The smallest and KISSer continuos-deploy I was able to create.
{ all-packages
, cachix
, derivationRecursiveFinder ? nyxUtils.derivationRecursiveFinder
, flakeSelf
, jq
, lib
, nix
, nyxUtils
, writeShellScriptBin
}:
let
  allPackagesList =
    builtins.map (xsx: xsx.drv)
      (lib.lists.filter (xsx: xsx.drv != null) packagesEval);

  depVar = drv:
    "_dep_${nyxUtils.drvHash drv}";

  depVarQuoted = drv:
    "\"$_dep_${nyxUtils.drvHash drv}\"";

  evalCommand = key: drv:
    let
      derivation = "$NYX_SOURCE#${key}";
      fullTag = output: "\"${derivationRecursiveFinder.join derivation output}\"";
      outputs = map fullTag drv.outputs;
      deps = nyxUtils.internalDeps allPackagesList drv;
      depsCond = lib.strings.concatStrings
        (builtins.map (dep: "[ ${depVarQuoted dep} == '1' ] && ") deps);
    in
    {
      cmd = ''
        ${depsCond}[ -z ${depVarQuoted drv} ] && ${depVar drv}=0 && \
        build "${key}" "${builtins.unsafeDiscardStringContext drv.outPath}" \
          ${lib.strings.concatStringsSep " \\\n  " outputs} && \
            ${depVar drv}=1
      '';
      inherit deps drv;
    };

  commentWarn = k: _: message:
    {
      cmd = "# ${message}: ${k}";
      drv = null;
      deps = [ ];
    };

  packagesEval =
    lib.lists.flatten
      (derivationRecursiveFinder.eval commentWarn evalCommand all-packages);

  depFirstSorter = pkgA: pkgB:
    if pkgA.drv == null || pkgB.drv == null then
      false
    else
      nyxUtils.drvElem pkgA.drv pkgB.deps;

  packagesEvalSorted =
    lib.lists.toposort depFirstSorter packagesEval;

  packagesCmds =
    builtins.map (pkg: pkg.cmd) packagesEvalSorted.result;
in
writeShellScriptBin "build-chaotic-nyx" ''
  NYX_SOURCE="''${NYX_SOURCE:-${flakeSelf}}"
  NYX_FLAGS="''${NYX_FLAGS:---accept-flake-config}"
  NYX_WD="''${NYX_WD:-$(mktemp -d)}"
  NYX_CHANGED_ONLY="''${NYX_CHANGED_ONLY:-}"
  R='\033[0;31m'
  G='\033[0;32m'
  Y='\033[1;33m'
  W='\033[0m'

  cd "$NYX_WD"
  echo -n "" > push.txt > errors.txt > success.txt > failures.txt > cached.txt > changed.txt

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

  if [ -n "$NYX_CHANGED_ONLY" ]; then
    _CURRENT=$(nix build --no-link --print-out-paths "$NYX_SOURCE#devShells.x86_64-linux.evaluator.NYX_EVALUATED" || exit 1)
    _FROM=$(nix build --no-link --print-out-paths "$NYX_CHANGED_ONLY#devShells.x86_64-linux.evaluator.NYX_EVALUATED" || exit 1)
    _CHANGED=$(comm -23 <(sort "$_CURRENT") <(sort "$_FROM") | cut -f 2)
    echo "$_CHANGED" > changed.txt
  fi

  function build() {
    _WHAT="''${1:- アンノーン}"
    _DEST="''${2:-/dev/null}"
    echo -n "Building $_WHAT..."
    # If NYX_CHANGED_ONLY is set, only build changed derivations
    if [ -n "$NYX_CHANGED_ONLY" ] && ! grep -Pq "^$_WHAT\$" changed.txt; then
      echo -e "''${Y} UNCHANGED''${W}"
      return 0
    elif cached "$_DEST"; then
      echo "$_WHAT" >> cached.txt
      echo -e "''${Y} CACHED''${W}"
      return 0
    elif \
      ( set -o pipefail;
        ${nix}/bin/nix build --json $NYX_FLAGS "''${@:3}" |\
          ${jq}/bin/jq -r '.[].outputs[]' \
      ) 2>> errors.txt >> push.txt
    then
      echo "$_WHAT" >> success.txt
      echo -e "''${G} OK''${W}"
      return 0
    else
      echo "$_WHAT" >> failures.txt
      echo -e "''${R} ERR''${W}"
      return 1
    fi
  }

  ${lib.strings.concatStringsSep "\n" packagesCmds}

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
