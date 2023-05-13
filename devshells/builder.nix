# The smallest and KISSer continuos-deploy I was able to create.
{ all-packages
, cachix
, derivationRecursiveFinder
, flakeSelf
, gnugrep
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
  NYX_FLAGS="''${NYX_FLAGS:---accept-flake-config --no-link}"
  NYX_WD="''${NYX_WD:-$(mktemp -d)}"
  R='\033[0;31m'
  G='\033[0;32m'
  Y='\033[1;33m'
  W='\033[0m'

  TMPDIR="''${NYX_TEMP:-''${TMPDIR}}"
  NIX_BUILD_TOP="''${NYX_TEMP:-''${NIX_BUILD_TOP}}"
  TMP="''${NYX_TEMP:-''${TMP}}"
  TEMP="''${NYX_TEMP:-''${TEMP}}"
  TEMPDIR="''${NYX_TEMP:-''${TEMPDIR}}"

  cd "$NYX_WD"
  echo -n "" > push.txt > errors.txt > success.txt > failures.txt > cached.txt > upstream.txt
  echo "{" > new-failures.nix

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
    ${nix}/bin/nix path-info "$2" --store "$1" >/dev/null 2>/dev/null
  }

  if [ -n "''${NYX_CHANGED_ONLY:-}" ]; then
    _DIFF=$(${nix}/bin/nix build --no-link --print-out-paths --impure --expr "(builtins.getFlake \"$NYX_SOURCE\").devShells.$(uname -m)-linux.comparer.passthru.any \"$NYX_CHANGED_ONLY\"" || exit 13)

    ln -s "$_DIFF" filter.txt
  fi

  function build() {
    _WHAT="''${1:- アンノーン}"
    _DEST="''${2:-/dev/null}"
    echo -n "Building $_WHAT..."
    # If NYX_CHANGED_ONLY is set, only build changed derivations
    if [ -f filter.txt ] && ! ${gnugrep}/bin/grep -Pq "^$_WHAT\$" filter.txt; then
      echo -e "''${Y} SKIP''${W}"
      return 0
    elif cached 'https://chaotic-nyx.cachix.org' "$_DEST"; then
      echo "$_WHAT" >> cached.txt
      echo -e "''${Y} CACHED''${W}"
      return 0
    elif cached 'https://cache.nixos.org' "$_DEST"; then
      echo "$_WHAT" >> upstream.txt
      echo -e "''${Y} CACHED-UPSTREAM''${W}"
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
      echo "  \"$_WHAT\" = \"$_DEST\";" >> failures.nix
      echo -e "''${R} ERR''${W}"
      return 1
    fi
  }

  ${lib.strings.concatStringsSep "\n" packagesCmds}

  echo "}" > new-failures.nix

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
