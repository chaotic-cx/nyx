{ deadnix
, findutils
, nixpkgs-fmt
, ripgrep
, statix
, writeShellScriptBin
}@p:
let
  find = "${p.findutils}/bin/find";
  rg = "${p.ripgrep}/bin/rg";
  fmt = "${p.nixpkgs-fmt}/bin/nixpkgs-fmt";
  statix = "${p.statix}/bin/statix";
  deadnix = "${p.deadnix}/bin/deadnix";
in
writeShellScriptBin "chaotic-nyx-lint" ''
  set -euo pipefail

  echo "Running nixpkgs-fmt..."
  ${fmt} --check .

  echo "Running statix..."
  ${statix} check

  echo "Running deadnix..."
  ${deadnix} --fail .

  echo "Searching ugly code..."
  _SHORT_FILES=$(${find} . -type f -name '*.nix' | ${rg} -P '[^\w"@\(](?!url|src|drv|xs|id|_?[kvxn])([a-zA-Z_][a-zA-Z]{0,2}):')
  _SHORT_FILES_EXIT=$?
  if [ -eq _SHORT_FILES_EXIT 0 ]; then
    echo "Lambda parameters can't have three letters or less (except: url, src, drv, x, xs, id, k, v, n):"
    echo "$_SHORT_FILES"
  fi

  echo 'Finished'
''
