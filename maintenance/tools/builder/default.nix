# The smallest and KISSer continuos-deploy I was able to create.
{ allPackages
, cachix
, coreutils-full
, nyxRecursionHelper
, flakeSelf
, findutils
, gnugrep
, jq
, git
, lib
, nix
, nyxUtils
, writeShellScriptBin
}:
let
  Jq = "${jq}/bin/jq";
  Nix = "${nix}/bin/nix";
  Grep = "${gnugrep}/bin/grep";
  Cachix = "${cachix}/bin/cachix";
  Xargs = "${findutils}/bin/xargs";

  allPackagesList =
    builtins.map (xsx: xsx.drv)
      (lib.lists.filter (xsx: xsx.drv != null) packagesEval);

  brokenOutPaths = builtins.attrValues (import ../../failures.nix);

  depVar = drv:
    "_dep_${nyxUtils.drvHash drv}";

  depVarQuoted = drv:
    "\"$_dep_${nyxUtils.drvHash drv}\"";

  allOutPaths = drv:
    let
      elem = x: "\"${builtins.unsafeDiscardStringContext drv.${x}.outPath}\"";
      xs = map elem drv.outputs;
    in
    lib.strings.concatStringsSep "\\\n  " xs;

  allOutFlakeKey = key: drv:
    let
      fullTag = output: "\"${nyxRecursionHelper.join key output}\"";
      taggedOutputs = map fullTag drv.outputs;
    in
    lib.strings.concatStringsSep " \\\n  " taggedOutputs;

  derivationMap = key: drv:
    let
      deps = nyxUtils.internalDeps allPackagesList drv;
      depsCond = lib.strings.concatStrings
        (builtins.map (dep: "[ ${depVarQuoted dep} == '1' ] && ") deps);
      mainOutPath = builtins.unsafeDiscardStringContext drv.outPath;
      thisVar = depVar drv;
    in
    if builtins.elem mainOutPath brokenOutPaths then
      doNotBuild ''
        echo "  \"${key}\" = \"${mainOutPath}\";" >> new-failures.nix
      ''
    else
      {
        cmd = ''
          _ALL_OUT_KEYS=(${allOutFlakeKey key drv})
          _ALL_OUT_PATHS=(${allOutPaths drv})
          ${depsCond}[ -z ${depVarQuoted drv} ] && ${thisVar}=0 && \
          build "${key}" "${mainOutPath}" && ${thisVar}=1
        '';
        inherit deps drv;
      };

  commentWarn = key: _v: message:
    doNotBuild ''
      echo "  \"${key}\" = \"${message}\";" >> eval-failures.nix
    '';

  doNotBuild = replacement:
    {
      cmd = replacement;
      drv = null;
      deps = [ ];
    };

  packagesEval =
    lib.lists.flatten
      (nyxRecursionHelper.derivations commentWarn derivationMap allPackages);

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
writeShellScriptBin "chaotic-nyx-build" ''
  # Cleanup PATH for reproducibility.
  # But, Cachix needs git in PATH.
  PATH="${coreutils-full}/bin:${git}/bin"

  # Options
  NYX_SOURCE="''${NYX_SOURCE:-${flakeSelf}}"
  NYX_FLAGS="''${NYX_FLAGS:---accept-flake-config --no-link}"
  NYX_WD="''${NYX_WD:-$(mktemp -d)}"

  # Colors
  R='\033[0;31m'
  G='\033[0;32m'
  Y='\033[1;33m'
  C='\033[1;36m'
  W='\033[0m'

  # Derivate temporary paths
  TMPDIR="''${NYX_TEMP:-''${TMPDIR}}"
  NIX_BUILD_TOP="''${NYX_TEMP:-''${NIX_BUILD_TOP}}"
  TMP="''${NYX_TEMP:-''${TMP}}"
  TEMP="''${NYX_TEMP:-''${TEMP}}"
  TEMPDIR="''${NYX_TEMP:-''${TEMPDIR}}"

  # Create empty logs and artifacts
  cd "$NYX_WD"
  touch push.txt errors.txt success.txt failures.txt cached.txt upstream.txt
  echo "{" | tee new-failures.nix > eval-failures.nix

  # Echo helpers
  function echo_warning() {
    echo -ne "''${Y}WARNING:''${W} "
    echo "$@"
  }

  function echo_error() {
    echo -ne "''${R}ERROR:''${W} " 1>&2
    echo "$@" 1>&2
  }

  # Warn if we don't have automated cachix
  if [ -z "$CACHIX_AUTH_TOKEN" ] && [ -z "$CACHIX_SIGNING_KEY" ]; then
    echo_warning "No key for cachix -- building anyway."
  fi

  # Check if $1 is in the cache
  function cached() {
    set -e
    ${Nix} path-info "$2" --store "$1" >/dev/null 2>/dev/null
  }

  # Creates list of what to build when only building what changed
  if [ -n "''${NYX_CHANGED_ONLY:-}" ]; then
    _DIFF=$(${Nix} build --no-link --print-out-paths --impure --expr "(builtins.getFlake \"$NYX_SOURCE\").devShells.$(uname -m)-linux.comparer.passthru.any \"$NYX_CHANGED_ONLY\"" || exit 13)

    ln -s "$_DIFF" filter.txt
  fi

  # Helper to zip-merge _ALL_OUT_KEYS and _ALL_OUT_PATHS
  function zip_path() {
    for (( i=0; i<''${#_ALL_OUT_KEYS[*]}; ++i)); do
      echo "''${_ALL_OUT_KEYS[$i]}" "''${_ALL_OUT_PATHS[$i]}"
    done
  }

  # Per-derivation build function
  function build() {
    _WHAT="''${1:- アンノーン}"
    _MAIN_OUT_PATH="''${2:-/dev/null}"
    _FULL_TARGETS=("''${_ALL_OUT_KEYS[@]/#/$NYX_SOURCE\#}")
    echo -n "* $_WHAT..."
    # If NYX_CHANGED_ONLY is set, only build changed derivations
    if [ -f filter.txt ] && ! ${Grep} -Pq "^$_WHAT\$" filter.txt; then
      echo -e "''${Y} SKIP''${W}"
      return 0
    elif [ -z "''${NYX_REFRESH:-}" ] && cached 'https://chaotic-nyx.cachix.org' "$_MAIN_OUT_PATH"; then
      echo "$_WHAT" >> cached.txt
      echo -e "''${Y} CACHED''${W}"
      zip_path >> full-pin.txt
      return 0
    elif cached 'https://cache.nixos.org' "$_MAIN_OUT_PATH"; then
      echo "$_WHAT" >> upstream.txt
      echo -e "''${Y} CACHED-UPSTREAM''${W}"
      return 0
    else
      (while true; do echo -ne "''${C} BUILDING''${W}\n* $_WHAT..." && sleep 120; done) &
      _KEEPALIVE=$!
      if \
        ( set -o pipefail;
          ${Nix} build --json $NYX_FLAGS "''${_FULL_TARGETS[@]}" |\
            ${Jq} -r '.[].outputs[]' \
        ) 2>> errors.txt >> push.txt
      then
        echo "$_WHAT" >> success.txt
        kill $_KEEPALIVE
        echo -e "''${G} OK''${W}"
        zip_path | tee -a to-pin.txt >> full-pin.txt
        return 0
      else
        echo "$_WHAT" >> failures.txt
        echo "  \"$_WHAT\" = \"$_MAIN_OUT_PATH\";" >> new-failures.nix
        kill $_KEEPALIVE
        echo -e "''${R} ERR''${W}"
        return 1
      fi
    fi
  }

  # Main list of functions
  ${lib.strings.concatStringsSep "\n" packagesCmds}

  # Write EOF of the artifacts
  echo "}" | tee -a new-failures.nix >> eval-failures.nix

  # Push logic
  if [ -z "$CACHIX_AUTH_TOKEN" ] && [ -z "$CACHIX_SIGNING_KEY" ]; then
    echo_error "No key for cachix -- failing to deploy."
    exit 23
  elif [ -n "''${NYX_RESYNC:-}" ] || [ -s push.txt ]; then
    # Let nix digest store paths first
    sleep 10

    # Push all new deriations with compression
    cat push.txt | ${Cachix} push chaotic-nyx \
      --compression-method zstd

    # Pin packages
    if [ -e to-pin.txt ]; then
      cat to-pin.txt | ${Xargs} -n 2 \
        ${Cachix} -v pin chaotic-nyx
    fi
  else
    echo_error "Nothing to push."
    exit 42
  fi

  # Useless exit but informative when running with "bash -x"
  exit 0
''
