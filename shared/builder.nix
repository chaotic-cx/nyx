{ all-packages
, cachix
, jq
, lib
, nix
, flakeSelf
, writeShellScriptBin
}:
let
  evalCommand = where: drvOutputs:
    let
      derivation = "${flakeSelf}#${where}";
      outputs = map (guide derivation) drvOutputs;
    in
    ''
      echo "Building ${derivation}"
      ${nix}/bin/nix build --json \
        ${lib.strings.concatStringsSep " \\\n  " outputs} |\
        ${jq}/bin/jq -r '.[].outputs[]' |\
        ${cachix}/bin/cachix push chaotic-nyx --compression-method zstd
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
  cd "$(mktemp -d)"

  ${packagesEval "" "" all-packages}
''
