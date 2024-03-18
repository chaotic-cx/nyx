<h1>Chaotic's Nyx</h1>

<img alt="Six frogs with capes, aligned like the NixOS logo, with intercalated shades of green" src="https://gist.githubusercontent.com/PedroHLC/f6eaa9dfcf190e18b753e98fd265c8d3/raw/nix-frog-with-capes-web.svg" />

<p>Nix flake for "too much bleeding-edge" and unreleased packages (e.g., mesa_git, linux_cachyos, firefox_nightly, sway_git, gamescope_git). And experimental modules (e.g., HDR, duckdns).</p>

<p>From the <a href="https://github.com/chaotic-cx">Chaotic Linux User Group (LUG)</a>, the same one that maintains <a href="https://aur.chaotic.cx">Chaotic-AUR</a>! 🧑🏻‍💻</p>

<p>The official source-code repository is available <a href="https://github.com/chaotic-cx/nyx">as "chaotic-cx/nyx" at GitHub</a>.</p>

<strong>PLEASE AVOID POSTING ISSUES IN NIXOS' MATRIX, DISCOURSE, DISCORD, ETC. USE <a href="https://github.com/chaotic-cx/nyx/issues">OUR REPO'S ISSUES</a>, <a href="https://t.me/chaotic_nyx_sac" target="_blank">TELEGRAM GROUP</a>, OR <code>#chaotic-nyx:ubiquelambda.dev</code> ON <a href="https://matrix.to/#/#chaotic-nyx:ubiquelambda.dev" target="_blank">MATRIX</a> INSTEAD.</strong>

<ul>
  <li><a href="#news">News</a></li>
  <li>
    <a href="#how-to-use-it">How to use it</a><br/>
    <ul>
      <li><a href="#on-nixos">On NixOS</a><br/></li>
      <li><a href="#on-home-manager">On Home-Manager</a><br/></li>
      <li><a href="#running-packages-without-installing">Running packages (without installing)</a><br/></li>
      <li><a href="#binary-cache-notes">Binary Cache notes</a><br/></li>
      <li><a href="#flakehub-notes">FlakeHub notes</a><br/></li>
    </ul>
  </li>
  <li><a href="#lists-of-options-and-packages">Lists of options and packages</a></li>
  <li>
    <a href="#harder-stuff">Harder stuff</a><br/>
    <ul>
      <li><a href="#using-linux-cachyos-with-sched-ext">Using linux-cachyos with sched-ext</a><br/></li>
      <li><a href="#using-qtile-from-git">Using qtile from git</a><br/></li>
    </ul>
  </li>
  <li><a href="#notes">Notes</a></li>
  <li><a href="#maintainence">Maintainence</a></li>
</ul>

<h2 id="news">News</h2>

<p>A news channel can be found <a href="https://t.me/s/chaotic_nyx">on Telegram</a>.</p>

<h2 id="how-to-use-it">How to use it</h2>

<h3 id="on-nixos">On NixOS</h3>

<p>We recommend integrating this repo using Flakes:</p>

<pre lang="nix"><code class="language-nix">
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };

  outputs = { nixpkgs, chaotic, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./configuration.nix # Your system configuration.
          chaotic.nixosModules.default # OUR DEFAULT MODULE
        ];
      };
    };
  };
}
</code></pre>

<p>In your <code>configuration.nix</code> enable the packages and options that you prefer:</p>

<pre lang="nix"><code class="language-nix">
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.input-leap-git ];
  chaotic.mesa-git.enable = true;
}
</code></pre>

<h3 id="on-home-manager">On Home-Manager</h3>

<p>This method is for home-manager setups <strong>without NixOS</strong>.</p>

<p>We recommend integrating this repo using Flakes:</p>

<pre lang="nix"><code class="language-nix">
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, chaotic, ... }: {
    homeConfigurations = {
      hostname = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home-manager/default.nix
          chaotic.homeManagerModules.default # OUR DEFAULT MODULE
        ];
      };
    };
  };
}
</code></pre>

<p>In your <code>home-manager/default.nix</code> add a <code>nix.package</code>, and enable the desired packages:</p>

<pre lang="nix"><code class="language-nix">
{ pkgs, ... }:
{
  nix.package = pkgs.nix;
  home.packages = [ pkgs.input-leap-git ];
}
</code></pre>

<h3 id="running-packages-without-installing">Running packages (without installing)</h2>

<p>Besides using our module/overlay, you can run packages (without installing them) using:</p>

<pre lang="sh"><code class="language-sh">
nix run github:chaotic-cx/nyx/nyxpkgs-unstable#firefox_nightly
</code></pre>

<h3 id="binary-cache-notes">Binary Cache notes</h3>

<p>You'll get the binary cache added to your configuration as soon as you add our default module.
We do this automatically, so we can gracefully update the cache's address and keys without prompting you for manual work.</p>

<p>If you dislike this behavior for any reason, you can disable it with <code>chaotic.nyx.cache.enable = false</code>.</p>

<p><strong>Remember</strong>: If you want to fetch derivations from our cache, you'll need to enable our module and rebuild your system <strong>before</strong> adding these derivations to your configuration.</p>

<p>Commands like <code>nix run ...</code>, <code>nix develop ...</code>, and others, when using our flake as input, will ask you to add the cache interactively when missing from your user's nix settings.</p>

<p>If you want to use the cache right from the <strong>installation media</strong>, install your system using <code>nixos-install --flake /mnt/etc/nixos#mymachine --option 'extra-substituters' 'https://nyx.chaotic.cx/' --option extra-trusted-public-keys "chaotic-nyx.cachix.org-1:HfnXSw4pj95iI/n17rIDy40agHj12WfF+Gqk6SonIT8="</code> (replace <code>mymachine</code> with your new host's name).</p>

<h3 id="flakehub-notes">FlakeHub notes</h3>

<a href="https://flakehub.com/flake/chaotic-cx/nyx"><img alt="FlakeHub" src="https://img.shields.io/endpoint?url=https://flakehub.com/f/chaotic-cx/nyx/badge" /></a>

<p>Add chaotic to your <code>flake.nix</code>, make sure to use the rolling <code>*.tar.gz</code> to keep using the latest packages:</p>

<pre lang="nix"><code class="language-nix">
{
  inputs.chaotic.url = "https://flakehub.com/f/chaotic-cx/nyx/*.tar.gz";
}
</code></pre>

<p>Then follow one of the guides above.</p>

<h2 id="lists-of-options-and-packages">Lists of options and packages</h2>

<!-- cut here --><p>An always up-to-date list of all our options and packages is available at: <a href="https://www.nyx.chaotic.cx/#lists">List page</a>.</p><!-- cut here -->

<h2 id="harder-stuff">Harder stuff</h2>

<p>Some packages are harder to use, I'll go into details in the following paragraphs.</p>

<h3 id="using-linux-cachyos-with-sched-ext">Using linux-cachyos with sched-ext</h3>

<p> Since sched-ext packages have been added to `linux-chachyos`, you can just use that kernel. </p>

<p>First, add this to your configuration:</p>

<pre lang="nix"><code class="language-nix">
{
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  environment.systemPackages =  [ pkgs.scx ];
}
</code></pre>

<p>Then, with the new kernel booted, check if the correct kernel booted:</p>

<pre lang="text"><code class="language-text">
╰─λ zgrep 'SCHED_CLASS' /proc/config.gz
CONFIG_SCHED_CLASS_EXT=y
</code></pre>

<p>The last step is to start a scheduler:</p>

<pre lang="text"><code class="language-text">
╰─λ sudo scx_rusty
21:38:53 [INFO] CPUs: online/possible = 24/32
21:38:53 [INFO] DOM[00] cpumask 00000000FF03F03F (20 cpus)
21:38:53 [INFO] DOM[01] cpumask 0000000000FC0FC0 (12 cpus)
21:38:53 [INFO] Rusty Scheduler Attached
</code></pre>

<p>There are other scx_* binaries for you to play with, or head to <a href="https://github.com/sched-ext/scx" target="_blank">github.com/sched-ext/scx</a> for instructions on how to write one of your own.</p>

<h3 id="using-qtile-from-git">Using qtile from git</h3>

<pre lang="nix"><code class="language-nix">
{
  services.xserver.windowManager.qtile = {
    enable = true;
    backend = "wayland";
    package = pkgs.qtile-module_git;
    extraPackages = _pythonPackages: [ pkgs.qtile-extras_git ];
  };
  # if you want a proper wayland+qtile session, and/or a "start-qtile" executable in PATH:
  chaotic.qtile.enable = true;
}
</code></pre>
<h2 id="notes">Notes</h2>

<h3>Our branches</h3>

<p>:godmode: Our <code>nyxpkgs-unstable</code> branch is the one that's always cached.</p>

<p>:shipit: The <code>main</code> branch is the primary target for contribution.</p>

<h3>Contributions</h3>

<p>We do accept third-party authored PRs.</p>

<h3>Upstream to nixpkgs</h3>

<p>If you are interested in pushing any of these packages to the upstream nixpkgs, you have our blessing.</p>

<p>If one of our contributors is mentioned in the deveriation's mantainers list (in this repository) please keep it when pushing to nixpkgs. But, please, tag us on the PR so we can participate in the reviewing.</p>

<h3>Forks and partial code-taking</h3>

<p>You are free to use our code, or portions of our code, following the MIT license restrictions.</p>

<h3>Suggestions</h3>

<p>If you have any suggestion to enhance our packages, modules, or even the CI's codes, let us know through the GitHub repo's issues.</p>

<h4>Building over the user's pkgs</h4>

<p>For cache reasons, Chaotic-Nyx now defaults to always use nixpkgs as provider of its dependencies.</p>

<p>If you need to change this behavior, set <code>chaotic.nyx.onTopOf = "user-pkgs";</code>. Be warned that you mostly won't be able to benefit from our binary cache after this change.</p>

<p>You can also disable our overlay entirely by configuring <code>chaotic.nyx.overlay.enable = false;</code>.</p>

<h2 id="maintainence">Maintainence</h2>

<p>The code in the <code>devshells</code> directory is used to automate our CIs and maintainence processes.</p>

<h3>Build them all</h3>

<p>To build all the packages and push their cache usptream, use:</p>

<pre lang="sh"><code class="language-sh">
nix develop . -c chaotic-nyx-build
</code></pre>

<p>This commands will properly skip already-known failures, evaluation failures, building failures, and even skip any chain of failures caused by internal-dependecies. It will also avoid to download what it's already in our cache and in the upstream nixpkgs' cache.</p>

<p>A list of what successfully built, failed to build, hashes of all failures, paths to push to cache and logs will be available at the <code>/tmp/nix-shell.*/tmp.*/</code> directory. This directory can be specified with the <code>NYX_WD</code> envvar.</p>

<h3>Check for evaluation differerences</h3>

<p>You can compare a branch with another like this:</p>

<pre lang="bash"><code class="language-bash">
machine=$(uname -m)-linux
A='github:chaotic-cx/nyx/branch-a'
B='github:chaotic-cx/nyx/branch-b'

nix build --impure --expr \
  "(builtins.getFlake \"$A\").devShells.$machine.comparer.passthru.any \"$B\""
</code></pre>

<p>After running, you'll find all the derivations that changed in the <code>result</code> file.</p>

<h4>Known failures</h4>

<p>All the hashes that are known to produce build-time failures are kept in <code>devshells/failures.nix</code>.</p>

<p>Our builder produces a <code>new-failures.nix</code> that must be used to update this file in every PR.</p>

<h4>Banished and rejected packages</h4>

<p>There are none (so far).</p>
