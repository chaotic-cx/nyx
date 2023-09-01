# The smallest and KISSer continuos-deploy I was able to create.
{ allPackages
, cachix
, coreutils-full
, nyxRecursionHelper
, flakeSelf
, gnugrep
, jq
, git
, lib
, nix
, nixpkgs
, nyxUtils
, writeShellScriptBin
}:
let
  Jq = "${jq}/bin/jq";
  Nix = "${nix}/bin/nix";
  Grep = "${gnugrep}/bin/grep";
  Cachix = "${cachix}/bin/cachix";

  allPackagesList =
    builtins.map (xsx: xsx.drv)
      (lib.lists.filter (xsx: xsx.drv != null) packagesEval);

  brokenOutPaths = builtins.attrValues (import ./failures.nix);

  depVar = drv:
    "_dep_${nyxUtils.drvHash drv}";

  depVarQuoted = drv:
    "\"$_dep_${nyxUtils.drvHash drv}\"";

  derivationMap = key: drv:
    let
      derivation = "$NYX_SOURCE#${key}";
      fullTag = output: "\"${nyxRecursionHelper.join derivation output}\"";
      outputs = map fullTag drv.outputs;
      deps = nyxUtils.internalDeps allPackagesList drv;
      depsCond = lib.strings.concatStrings
        (builtins.map (dep: "[ ${depVarQuoted dep} == '1' ] && ") deps);
      outPath = builtins.unsafeDiscardStringContext drv.outPath;
    in
    if builtins.elem outPath brokenOutPaths then
      doNotBuild ''
        echo "  \"${key}\" = \"${outPath}\";" >> new-failures.nix
      ''
    else
      {
        cmd = ''
          ${depsCond}[ -z ${depVarQuoted drv} ] && ${depVar drv}=0 && \
          build "${key}" "${outPath}" \
            ${lib.strings.concatStringsSep " \\\n  " outputs} && \
              ${depVar drv}=1
        '';
        inherit deps drv;
      };

  commentWarn = k: _v: message:
    doNotBuild "# ${message}: ${k}";

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
  PATH="${coreutils-full}/bin:${git}/bin"

  NYX_SOURCE="''${NYX_SOURCE:-${flakeSelf}}"
  NYX_FLAGS="''${NYX_FLAGS:---accept-flake-config --no-link}"
  NYX_WD="''${NYX_WD:-$(mktemp -d)}"
  R='\033[0;31m'
  G='\033[0;32m'
  Y='\033[1;33m'
  C='\033[1;36m'
  W='\033[0m'

  TMPDIR="''${NYX_TEMP:-''${TMPDIR}}"
  NIX_BUILD_TOP="''${NYX_TEMP:-''${NIX_BUILD_TOP}}"
  TMP="''${NYX_TEMP:-''${TMP}}"
  TEMP="''${NYX_TEMP:-''${TEMP}}"
  TEMPDIR="''${NYX_TEMP:-''${TEMPDIR}}"

  cd "$NYX_WD"
  echo -n "" > push.txt > errors.txt > success.txt > failures.txt > cached.txt > upstream.txt
  echo "{" > new-failures.nix
  echo "{chaotic ? builtins.getFlake \"$NYX_SOURCE\", system ? builtins.currentSystem}: with chaotic.packages.\''${system}; [" > new-success.nix

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
    ${Nix} path-info "$2" --store "$1" >/dev/null 2>/dev/null
  }

  if [ -n "''${NYX_CHANGED_ONLY:-}" ]; then
    _DIFF=$(${Nix} build --no-link --print-out-paths --impure --expr "(builtins.getFlake \"$NYX_SOURCE\").devShells.$(uname -m)-linux.comparer.passthru.any \"$NYX_CHANGED_ONLY\"" || exit 13)

    ln -s "$_DIFF" filter.txt
  fi

  function build() {
    _WHAT="''${1:- アンノーン}"
    _DEST="''${2:-/dev/null}"
    _FULL=("''${@:3}")
    echo -n "* $_WHAT..."
    # If NYX_CHANGED_ONLY is set, only build changed derivations
    if [ -f filter.txt ] && ! ${Grep} -Pq "^$_WHAT\$" filter.txt; then
      echo -e "''${Y} SKIP''${W}"
      return 0
    elif [ -z "''${NYX_REFRESH:-}" ] && cached 'https://chaotic-nyx.cachix.org' "$_DEST"; then
      echo "$_WHAT" >> cached.txt
      echo -e "''${Y} CACHED''${W}"
      echo "  ''${_FULL[@]#*\#}" >> new-success.nix
      return 0
    elif cached 'https://cache.nixos.org' "$_DEST"; then
      echo "$_WHAT" >> upstream.txt
      echo -e "''${Y} CACHED-UPSTREAM''${W}"
      return 0
    else
      (while true; do echo -ne "''${C} BUILDING''${W}\n* $_WHAT..." && sleep 120; done) &
      _KEEPALIVE=$!
      if \
        ( set -o pipefail;
          ${Nix} build --json $NYX_FLAGS "''${_FULL[@]}" |\
            ${Jq} -r '.[].outputs[]' \
        ) 2>> errors.txt >> push.txt
      then
        echo "$_WHAT" >> success.txt
        kill $_KEEPALIVE
        echo -e "''${G} OK''${W}"
        echo "''${_FULL[@]#*\#}" >> new-success.nix
        return 0
      else
        echo "$_WHAT" >> failures.txt
        echo "  \"$_WHAT\" = \"$_DEST\";" >> new-failures.nix
        kill $_KEEPALIVE
        echo -e "''${R} ERR''${W}"
        return 1
      fi
    fi
  }

  ${lib.strings.concatStringsSep "\n" packagesCmds}

  echo "}" >> new-failures.nix
  echo "]" >> new-success.nix

  if [ -n "''${NYX_PIN:-}" ]; then
    echo "Building pin file..."
    ${Nix} build -L --out-link pin.txt --impure --expr 'with import "${nixpkgs}" {}; writeText "pin.txt" (builtins.concatStringsSep "\n" (import ./new-success.nix { }))'
  fi

  if [ -z "$CACHIX_AUTH_TOKEN" ] && [ -z "$CACHIX_SIGNING_KEY" ]; then
    echo_error "No key for cachix -- failing to deploy."
    exit 23
  elif [ -n "''${NYX_RESYNC:-}" ] || [ -s push.txt ]; then
    # Let nix digest store paths first
    sleep 10

    echo "Pushing to cache..."
    cat push.txt | ${Cachix} push chaotic-nyx \
      --compression-method zstd

    if [ -e pin.txt ]; then
      _DT=$(TZ=UTC date +%y%m%d%H%S)
      readlink pin.txt | ${Cachix} push chaotic-nyx \
        --compression-method zstd
      ${Cachix} -v pin chaotic-nyx \
        "nyxpkgs-unstable" \
        "$(readlink pin.txt)"
    fi

  else
    echo_error "Nothing to push."
    exit 42
  fi

  exit 0
''
