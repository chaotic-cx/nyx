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
, hostPlatform
}:
let
  path = lib.makeBinPath [
    coreutils-full
    # cachix requires "git" in PATH
    git
    jq
    nix
    gnugrep
    cachix
    findutils
  ];

  allPackagesList =
    builtins.map (xsx: xsx.drv)
      (lib.lists.filter (xsx: xsx.drv != null) packagesEval);

  brokenOutPaths = builtins.attrValues (import "${flakeSelf}/maintenance/failures.${hostPlatform.system}.nix");

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
      echo "${key}: ${message}" >> eval-failures.txt
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
  PATH="${path}"

  # Options (1)
  NYX_SOURCE="''${NYX_SOURCE:-${flakeSelf}}"
  NYX_TARGET="''${NYX_TARGET:-${hostPlatform.system}}"

  NYX_PREFIX=""
  if [ -z "$NYX_PREFIX" ] && [ "$NYX_TARGET" != 'x86_64-linux' ]; then
    NYX_PREFIX="''${NYX_TARGET%-linux}."
  fi

  # All the required functions
  source ${./lib.sh}

  # Build jobs
  function build-jobs() {
    ${lib.strings.concatStringsSep "\n" packagesCmds}

    return 0
  }

  # Phases system
  function default-phases () {
    prepare
    build-jobs
    finish
    deploy
  }
  PHASES=''${PHASES:-default-phases};
  for phase in $PHASES; do $phase; done

  # Useless exit but informative when running with "bash -x"
  exit 0
''
