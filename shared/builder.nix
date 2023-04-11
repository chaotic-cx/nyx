# The smallest and KISSer continuos-deploy I was able to create.
{ all-packages
, cachix
, jq
, lib
, nix
, flakeSelf
, writeShellScriptBin
, writeShellScript
}:
let
  evalCommand = where: drvOutputs:
    let
      derivation = "$NYX_SOURCE#${where}";
      fullTag = output: "\"${guide derivation output}\"";
      outputs = map fullTag drvOutputs;
    in
    ''
      build "${where}" \
        ${lib.strings.concatStringsSep " \\\n  " outputs}
    '';

  guide = namespace: n:
    if namespace != "" then
      "${namespace}.${n}"
    else
      n
  ;
  packagesEval = namespace: n: v:
    (if (builtins.tryEval v).success then
      (if lib.attrsets.isDerivation v then
        (if (v.meta.broken or true) then
          "# broken: ${n}"
        else if (v.meta.unfree or true) then
          "# unfree: ${n}"
        else
          evalCommand (guide namespace n) v.outputs
        )
      else if builtins.isAttrs v then
        lib.strings.concatStringsSep "\n"
          (lib.attrsets.mapAttrsToList (packagesEval (guide namespace n)) v)
      else
        "# unrelated: ${n}"
      )
    else
      "# not evaluating: ${n}"
    )
  ;
in
writeShellScriptBin "build-chaotic-nyx" ''
  NYX_SOURCE="''${NYX_SOURCE:-${flakeSelf}}"
  NYX_FLAGS="''${NYX_FLAGS:---accept-flake-config}"
  NYX_WD="''${NYX_WD:-$(mktemp -d)}"
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

  function build() {
    _WHAT="''${1:- アンノーン}"
    echo -n "Building $_WHAT..."
    if \
      ( set -o pipefail;
        ${nix}/bin/nix build --json $NYX_FLAGS "''${@:2}" |\
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

  ${packagesEval "" "" all-packages}

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
