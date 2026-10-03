{
  lib,
  writeShellScriptBin,
  nixfmt-tree,
  prettier,
  shellcheck,
  shfmt,
  ...
}:
let
  nixFormatter = nixfmt-tree.override {
    settings = {
      tree-root-file = ".git/index";
      excludes = [
        "maintenance/failures.aarch64-darwin.nix"
        "maintenance/failures.aarch64-linux.nix"
        "maintenance/failures.x86_64-linux.nix"
      ];
      formatter.nixfmt = {
        command = "nixfmt";
        includes = [ "*.nix" ];
      };
      formatter.shfmt = {
        command = lib.getExe shfmt;
        options = [ "-w" ];
        includes = [ "*.sh" ];
      };
      formatter.prettier = {
        command = lib.getExe prettier;
        options = [ "-w" ];
        includes = [
          "*.json"
          "*.md"
          "*.yaml"
          "*.yml"
        ];
      };
    };
  };

  script = ''
    set -euo pipefail

    ${lib.getExe nixFormatter} "$@"

    filtered_scripts=()
    for arg in "$@"; do
        if [[ ! "$arg" == -* ]] && [[ "$arg" == *.sh ]]; then
            filtered_scripts+=("$arg")
        fi
    done

    if [ "''${#filtered_scripts[@]}" -gt 0 ]; then
      _SHELLCHECK_OUT=$(${lib.getExe shellcheck} -af diff "''${filtered_scripts[@]}" || true)
      if [ -n "$_SHELLCHECK_OUT" ]; then
        echo "$_SHELLCHECK_OUT" | git apply
      fi
    fi
  '';
in
(writeShellScriptBin "chaotic-nyx-formatter" script).overrideAttrs (prevAttrs: {
  passthru = prevAttrs.passthru // {
    inherit nixFormatter;
  };
})
