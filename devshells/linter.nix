{ deadnix
, findutils
, nixpkgs-fmt
, ripgrep
, statix
, writeShellScriptBin
}:
let
  Find = "${findutils}/bin/find";
  Rg = "${ripgrep}/bin/rg";
  Fmt = "${nixpkgs-fmt}/bin/nixpkgs-fmt";
  Statix = "${statix}/bin/statix";
  Deadnix = "${deadnix}/bin/deadnix";
in
writeShellScriptBin "chaotic-nyx-lint" ''
  set -euo pipefail

  echo "Running nixpkgs-fmt..."
  ${Fmt} --check .

  echo "Running statix..."
  ${Statix} check

  echo "Running deadnix..."
  ${Deadnix} --fail .

  echo "Searching ugly code..."
  _SHORT_FILES=$(${Find} . -type f -name '*.nix' | (xargs ${Rg} -P '[^\w"@\(](?!url|src|drv|xs|id|_?[kvxn])([a-zA-Z_][a-zA-Z]{0,2}):' || true))
  if [[ -n "$_SHORT_FILES" ]]; then
    echo "Lambda parameters can't have three letters or less (except: url, src, drv, x, xs, id, k, v, n):"
    echo "$_SHORT_FILES"
  fi

  echo 'Finished'
''
