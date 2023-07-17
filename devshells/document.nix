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
      htmlify = builtins.replaceStrings [ "\n" " " ] [ "<br/>" "&nbsp;" ];
      prettify = src:
        htmlify (lib.generators.toPretty { multiline = true; } src);
      exampleValue =
        if (v.example or null) == null then ""
        else if (v.example._type or null) == "literalExpression"
        then htmlify v.example.text
        else prettify v.example;
      example =
        if (builtins.stringLength exampleValue > 0) then
          "<br/><b>Example:</b> <code>${exampleValue}</code><br/>"
        else "";
      typeDescription =
        if v.type.name == "enum" then
          "<br/><b>Enum:</b> <code>${v.type.description}</code><br/>"
        else "";
    in
    ''
      <tr>
        <td><code>chaotic.${k}</code></td>
        <td><code>${prettify v.default}</code></td>
        <td>${htmlify v.description}
          ${typeDescription}
          ${example}
        </td>
      </tr>
    '';

  optionWarn = k: _: message:
    ''
      <tr>
        <td><code>chaotic.${k}</code></td>
        <td><code>-</code></td>
        <td>(${message})</td>
      </tr>
    '';

  optionsEval = nyxRecursionHelper.options optionWarn optionMap loadedModule.options.chaotic;

  optionsEvalFlat =
    lib.lists.flatten optionsEval;
in
writeText "chaotic-documented.html" ''
  <!DOCTYPE html><html>
  <head lang="en">
    <meta charset="UTF-8" />
    <title>List of packages and options - Chaotic-Nyx</title>
    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">
    <meta name="description" property="og:description"
      content="Documentation of all our packages and options." />
    <meta property="og:title"
      content="Chaotic-Nyx - Nix flake for bleeding-edge and unreleased packages." />
    <link rel="icon" href="https://avatars.githubusercontent.com/u/130499842?v=4" type="image/jpeg" />
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
    <p>This page only contains information about packages and options.</p>
    <p>For instructions, support and details about this project, check the project's <a href="https://github.com/chaotic-cx/nyx#readme">README</a>.</p>
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
        <th>Default</th>
        <th>Description</th>
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
        sort: true,
        style: { table: { 'overflow-wrap': 'break-word' } }
      }).render(document.getElementById("js-options"));
    </script>
  </body></html>
''
