# The smallest and KISSer continuos-deploy I was able to create.
{
  dry-build,
  lib,

  coreutils-full,
  cachix,
  curl,
  findutils,
  git,
  gnugrep,
  gnused,
  jq,
  nix,

  writeShellScriptBin,
}:
let
  path = lib.makeBinPath [
    coreutils-full
    cachix
    curl
    findutils
    git # cachix requires "git" in PATH
    gnugrep
    gnused
    jq
    nix
  ];

  packagesCmds = map cmdMap dry-build.passthru.packagesCmds;
  inherit (dry-build.passthru) system flakeSelf;

  quote = x: "\"${x}\"";
  depVar = dep: "_dep_${dep}";
  depVarQuoted = dep: quote "$_dep_${dep}";

  allOutPaths =
    artifacts: lib.strings.concatStringsSep " \\\n  " (map quote (builtins.attrValues artifacts));
  allOutFlakeKey =
    artifacts: lib.strings.concatStringsSep " \\\n  " (map quote (builtins.attrNames artifacts));

  cmdMap =
    cmd:
    let
      depsCond = lib.strings.concatStrings (
        builtins.map (dep: "[ ${depVarQuoted dep} == '1' ] && ") cmd.deps
      );
      thisVar = depVar cmd.this;
      knownIssue = cmd.issue or null;
    in
    if knownIssue == "skip" then
      ''
        ${thisVar}=0 && echo "  \"${cmd.key}\" = \"skip\";" >> new-failures.nix
      ''
    else if cmd.build then
      ''
        _ALL_OUT_KEYS=(${allOutFlakeKey cmd.artifacts})
        _ALL_OUT_PATHS=(${allOutPaths cmd.artifacts})
        _MAIN_OUT_PATH="${cmd.mainOutPath}"
        _MAIN_OUT_HASH=${cmd.thisOut}
        _WHAT="${cmd.key}"
        _KNOWN_ISSUE="${
          if knownIssue != null && !lib.strings.isStorePath knownIssue then cmd.issue else ""
        }"
        _PREV=${depVarQuoted cmd.this}
        ${depsCond}[ -z "$_PREV" ] && ${thisVar}=0 && \
        build && ${thisVar}=1 || failure
      ''
    else if cmd ? broken then
      ''
        ${thisVar}=0 && echo "  \"${cmd.key}\" = \"${cmd.broken}\";" >> new-failures.nix
      ''
    else if cmd ? warn then
      ''
        echo "${cmd.key}: ${cmd.warn}" >> eval-failures.txt
      ''
    else
      ''
        echo "${cmd.key}: unexplained skip" >> eval-failures.txt
      '';

in
writeShellScriptBin "chaotic-nyx-build" ''
  # Cleanup PATH for reproducibility.
  PATH="${path}"

  # Options (1)
  NYX_SOURCE="''${NYX_SOURCE:-${flakeSelf}}"
  NYX_TARGET="''${NYX_TARGET:-${system}}"

  NYX_PREFIX=""
  if [ -z "$NYX_PREFIX" ] && [ "$NYX_TARGET" != 'x86_64-linux' ]; then
    NYX_PREFIX="''${NYX_TARGET%-linux}."
  fi

  # All the required functions
  source ${./lib.sh}

  # Build jobs
  function build-jobs() {
    set +u
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
