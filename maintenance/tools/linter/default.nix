{
  deadnix,
  findutils,
  formatter,
  ripgrep,
  statix,
  writeShellScriptBin,
}:
let
  Find = "${findutils}/bin/find";
  Rg = "${ripgrep}/bin/rg";
  Fmt = "${formatter}/bin/treefmt";
  Statix = "${statix}/bin/statix";
  Deadnix = "${deadnix}/bin/deadnix";
in
writeShellScriptBin "chaotic-nyx-lint" ''
  set -euo pipefail

  ${Fmt} --ci
  ${Statix} check .
  ${Deadnix} --fail .

  _SHORT_FILES=$(${Find} . -type f -name '*.nix' | (xargs ${Rg} -P '[^\w"-\/\{](?!_?xs|_?id|_?[kvx]:)(_?[a-zA-Z_][a-zA-Z_-]?:)(?!\w)' || true))
  if [[ -n "$_SHORT_FILES" ]]; then
    echo "Lambda parameters can't have two letters or less (except: x, xs, id, k, v):"
    echo "$_SHORT_FILES"
  fi
''
