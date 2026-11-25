# Reuse Helix's source selection and replace the parser build with metadata.
/^[[:space:]]+source[[:space:]]*=/ {
  sourceCount++
  readingSource = 1
}

readingSource {
  print
  if (/;[[:space:]]*$/) {
    print "    in {"
    print "      inherit (grammar) name;"
    print "      inherit (grammar.source) rev;"
    print "      inherit (source) narHash lastModified lastModifiedDate;"
    print "      type = if isGitHubGrammar grammar then \"github\" else \"git\";"
    print "      owner = if isGitHubGrammar grammar then gh.owner else null;"
    print "      repo = if isGitHubGrammar grammar then gh.repo else null;"
    print "      url = if isGitHubGrammar grammar then null else grammar.source.git;"
    print "      subpath = grammar.source.subpath or null;"
    print "    };"
    readingSource = 0
    skippingBuild = 1
  }
  next
}

/^[[:space:]]*grammarsToBuild[[:space:]]*=/ {
  buildCount++
  if (!skippingBuild) badOrder = 1
  skippingBuild = 0
}

# Return metadata in name order, as in the existing languages JSON.
/^in[[:space:]]*$/ {
  resultCount++
  if (skippingBuild || !buildCount) badOrder = 1
  print "in builtins.toJSON (builtins.attrValues (builtins.listToAttrs builtGrammars))"
  skippingResult = 1
  next
}

!skippingBuild && !skippingResult { print }

END {
  if (sourceCount != 1 || buildCount != 1 || resultCount != 1 || readingSource || badOrder) {
    print "Unexpected Helix grammars.nix structure" > "/dev/stderr"
    exit 1
  }
}
