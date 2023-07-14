{ allPackages
, defaultModule
, lib
, nixosSystem
, nyxRecursionHelper
, nyxUtils
, system
, writeText
}:
let
  derivationMap = k: v:
    let
      description =
        if (builtins.stringLength (v.meta.longDescription or "") > 0) then
          v.meta.longDescription
        else v.meta.description or "-";
      homepage =
        if (builtins.stringLength (v.meta.homepage or "") > 0) then
          "<a href=\"${v.meta.homepage}\" target=\"_blank\">${v.meta.homepage}</a>"
        else "";
    in
    ''
      <tr>
        <td><code>${k}</code></td>
        <td><code>${v.version or "-"}</code></td>
        <td>${description}<br/>${homepage}</td>
      </tr>
    '';

  derivationWarn = k: v: message:
    if message == "unfree" then derivationMap k v
    else ''
      <tr>
        <td><code>${k}</code></td>
        <td><code>-</code></td>
        <td>${v._description or "(${message})"}</td>
      </tr>
    '';

  packagesEval = nyxRecursionHelper.derivationsLimited 1 derivationWarn derivationMap allPackages;

  packagesEvalFlat =
    lib.lists.flatten packagesEval;

  loadedModule = nixosSystem { modules = [ defaultModule ]; system = "x86_64-linux"; };

  optionMap = k: v:
    let
      prettify = src:
        builtins.replaceStrings [ "\n" " " ] [ "<br/>" "&nbsp;" ]
          (lib.generators.toPretty { multiline = true; } src);
      example =
        if (v.example or null) == null then "-"
        else if (v.example._type or null) == "literalExpression"
        then v.example.text
        else prettify v.example
      ;
    in
    ''
      <tr>
        <td><code>${k}</code></td>
        <td>${v.description}</td>
        <td><code>${prettify v.default}</code></td>
        <td><code>${example}</code></td>
      </tr>
    '';

  optionWarn = k: _: message:
    ''
      <tr>
        <td><code>${k}</code></td>
        <td>(${message})</td>
      </tr>
    '';

  optionsEval = nyxRecursionHelper.options optionWarn optionMap loadedModule.options.chaotic;

  optionsEvalFlat =
    lib.lists.flatten optionsEval;
in
writeText "chaotic-documented.html" ''
  <!DOCTYPE html><html>
  <head>
    <meta charset="UTF-8" />
    <title>Chaotic-Nyx - Nix flake for bleeding-edge and unreleased packages.</title>
    <link href="https://unpkg.com/gridjs/dist/theme/mermaid.min.css" rel="stylesheet" />
    <link rel="stylesheet" href="https://rsms.me/inter/inter.css">
    <style>
      .noscript-table { display: none; }
      :root { font-family: 'Inter', sans-serif; }
      @supports (font-variation-settings: normal) {
        :root { font-family: 'Inter var', sans-serif; }
      }
    </style>
    <noscript><style>.noscript-table { display: table; }</style></noscript>
  </head><body>
    <h1>Chaotic-Nyx</h1>
    <h2>Packages</h2>
    <table id="packages" class="noscript-table" border="1">
      <thead>
        <th>Name</th>
        <th>Version</th>
        <th>Description</th>
      </thead>
      <tbody>${lib.strings.concatStrings packagesEvalFlat}</tbody>
    </table>
    <div id="js-packages"></div>
    <h2>Options</h2>
    <table id="options" class="noscript-table" border="1">
      <thead>
        <th>Key</th>
        <th>Description</th>
        <th>Default</th>
        <th>Example</th>
      </thead>
      <tbody>${lib.strings.concatStrings optionsEvalFlat}</tbody>
    </table>
    <div id="js-options"></div>
    <script type="module">
      import {
        Grid,
        html
      } from "https://unpkg.com/gridjs?module";

      new Grid({
        from: document.getElementById("packages"),
        search: true,
        sort: true
      }).render(document.getElementById("js-packages"));

      new Grid({
        from: document.getElementById("options"),
        search: true,
        sort: true
      }).render(document.getElementById("js-options"));
    </script>
  </body></html>
''
