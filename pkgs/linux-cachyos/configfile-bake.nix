{ runCommand, configfile }:
# taken from
runCommand "config.nix" { } ''
  echo "{" > "$out"
  while IFS='=' read key val; do
    [ "x''${key#CONFIG_}" != "x$key" ] || continue
    no_firstquote="''${val#\"}";
    echo '  "'"$key"'" = "'"''${no_firstquote%\"}"'";' >> "$out"
  done < "${configfile}"
  echo "}" >> $out
''
