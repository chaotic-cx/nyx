<h1>Chaotic's Nyx</h1>

<img alt="Six frogs with capes, aligned like the NixOS logo, with intercalated shades of green" src="https://gist.githubusercontent.com/PedroHLC/f6eaa9dfcf190e18b753e98fd265c8d3/raw/nix-frog-with-capes-web.svg" width="35%" /><br/>

<img alt="GitHub's menu buttons re-ordered and re-labeled to say: Make Pull requests Not Issues. Sounding like Make Love Not War" src="https://gist.githubusercontent.com/PedroHLC/eba5644666a1f2f007319d566ab77a83/raw/91c6064eb0d5cd1e19ac76a48acda87996f330f9/make-pr-not-issues.svg" width="330" height="49" /><br/>

<p>Nix flake for "too much bleeding-edge" and unreleased packages (e.g., mesa_git, linux_cachyos, firefox_nightly, sway_git, gamescope_git). And experimental modules (e.g., HDR, duckdns). And yes, WE'RE BACK FROM THE DEAD!</p>

<p>From the <a href="https://github.com/chaotic-cx">Chaotic Linux User Group (LUG)</a>, the same one that maintains <a href="https://aur.chaotic.cx">Chaotic-AUR</a>! 🧑🏻‍💻</p>

<p>The official source-code repository is available <a href="https://github.com/chaotic-cx/nyx">as "chaotic-cx/nyx" at GitHub</a>.</p>

<strong>PLEASE AVOID POSTING ISSUES IN NIXOS' MATRIX, DISCOURSE, DISCORD, ETC. USE <a href="https://github.com/chaotic-cx/nyx/issues">OUR REPO'S ISSUES</a>, <a href="https://t.me/chaotic_nyx_sac" target="_blank">TELEGRAM GROUP</a>, OR <code>#chaotic-nyx:ubiquelambda.dev</code> ON <a href="https://matrix.to/#/#chaotic-nyx:ubiquelambda.dev" target="_blank">MATRIX</a> INSTEAD.</strong>

<ul>
  <li><a href="#news">News</a></li>
  <li>
    <a href="#how-to-use-it">How to use it</a><br/>
    <ul>
      <li><a href="#on-nixos-unstable">On NixOS unstable</a></li>
      <li><a href="#on-nixos-stable">On NixOS stable</a></li>
      <li><a href="#on-home-manager">On Home-Manager</a></li>
      <li><a href="#running-packages-without-installing">Running packages (without installing)</a></li>
      <li><a href="#binary-cache-notes">Binary Cache notes</a></li>
      <li><a href="#flakehub-notes">FlakeHub notes</a></li>
      <li><a href="#cachyos-notes">CachyOS notes</a></li>
      <li><a href="#using-with-read-only-pkgs">Using with read-only pkgs</a></li>
      <li><a href="#using-with-jovian">Using with Jovian</a></li>
    </ul>
  </li>
  <li><a href="#lists-of-options-and-packages">Lists of options and packages</a></li>
  <li><a href="#notes">Notes</a></li>
  <li><a href="#criteria-for-new-packages">Criteria for new packages</a></li>
  <li><a href="#why-am-i-building-a-kernel-basic-cache-troubleshooting">Why am I building a kernel? Basic cache troubleshooting</a></li>
</ul>

<h2 id="news">News</h2>

<p>A news channel can be found <a href="https://t.me/s/chaotic_nyx">on Telegram</a>.</p>

<h2 id="how-to-use-it">How to use it</h2>

<h3 id="on-nixos-unstable">On NixOS unstable</h3>

<p>This tutorial does not apply for users using NixOS 24.11 and other stable channels. This tutorial is for unstable users.</p>

<p>We recommend integrating this repo using Flakes:</p>

<pre lang="nix"><code class="language-nix">
# flake.nix
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable"; # IMPORTANT
  };

  outputs = { nixpkgs, chaotic, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem { # Replace "hostname" with your system's hostname
        system = "x86_64-linux";
        modules = [
          ./configuration.nix
          chaotic.nixosModules.default # IMPORTANT
        ];
      };
    };
  };
}
</code></pre>

<p>In your <code>configuration.nix</code> enable the packages and options that you prefer:</p>

<pre lang="nix"><code class="language-nix">
# configuration.nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.lan-mouse_git ];
  chaotic.mesa-git.enable = true;
}
</code></pre>

<h3 id="on-nixos-stable">On NixOS stable</h3>

<p>Chaotic-Nyx is <strong>NOT</strong> compatible with NixOS 25.05 and older.</p>

<p>This tutorial does not apply for users using NixOS unstable channel. This tutorial is for 24.11 and other stable channels.</p>

<p>You won't have access to all the modules and options available to unstable users, as those are prone to breaking due to the divergence between the channels.
But you'll have access to all packages, the cache, and the registry.</p>

<p>We recommend integrating this repo using Flakes:</p>

<pre lang="nix"><code class="language-nix">
# flake.nix
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
  };

  outputs = { nixpkgs, chaotic, ... }: {
    nixosConfigurations = {
      hostname = nixpkgs.lib.nixosSystem { # Replace "hostname" with your system's hostname
        system = "x86_64-linux";
        modules = [
          ./configuration.nix # Your system configuration.
          chaotic.nixosModules.nyx-cache
          chaotic.nixosModules.nyx-overlay
          chaotic.nixosModules.nyx-registry
        ];
      };
    };
  };
}
</code></pre>

<p>In your <code>configuration.nix</code> enable the packages that you prefer:</p>

<pre lang="nix"><code class="language-nix">
# configuration.nix
{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.lan-mouse_git ];
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
}
</code></pre>

<h3 id="on-home-manager">On Home-Manager</h3>

<p>This method is for home-manager setups <strong>without NixOS</strong>.</p>

<p>We recommend integrating this repo using Flakes:</p>

<pre lang="nix"><code class="language-nix">
# flake.nix
{
  description = "My configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable"; # IMPORTANT
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, chaotic, ... }: {
    # ... other outputs
    homeConfigurations = {
      # ... other configs
      configName = home-manager.lib.homeManagerConfiguration { # Replace "configName" with a significant unique name
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [
          ./home-manager/default.nix
          chaotic.homeModules.default # IMPORTANT
        ];
      };
    };
  };
}
</code></pre>

<p>In your <code>home-manager/default.nix</code> add a <code>nix.package</code>, and enable the desired packages:</p>

<pre lang="nix"><code class="language-nix">
# configuration.nix
{ pkgs, ... }:
{
  nix.package = pkgs.nix;
  home.packages = [ pkgs.lan-mouse_git ];
}
</code></pre>

<h3 id="running-packages-without-installing">Running packages (without installing)</h3>

<p>Besides using our module/overlay, you can run packages (without installing them) using:</p>

<pre lang="sh"><code class="language-sh">
nix run github:chaotic-cx/nyx/nyxpkgs-unstable#firefox_nightly
</code></pre>

<h3 id="binary-cache-notes">Binary Cache notes</h3>

<p>You'll get the binary cache added to your configuration as soon as you add our default module.
We do this automatically, so we can gracefully update the cache's address and keys without prompting you for manual work.</p>

<p>If you dislike this behavior for any reason, you can disable it with <code>chaotic.nyx.cache.enable = false</code>.</p>

<p><strong>!!!!!!!!!:</strong>: You'll need to enable our module and rebuild your system <strong>before</strong> adding these derivations to your configuration. Another option, or if you want to use the cache right from the <strong>installation media</strong>, install your system adding <code>--option 'extra-substituters' 'https://nyx-cache.chaotic.cx/' --option extra-trusted-public-keys "nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk="</code> to the end of the <code>nixos-install</code> (or <code>nixos-rebuild</code>) command.</p>

<p>Commands like <code>nix run ...</code>, <code>nix develop ...</code>, and others, when using our flake as input, will ask you to add the cache interactively when missing from your user's nix settings.</p>
<p>We offer cache for <code>x86_64-linux</code>, <code>aarch64-linux</code>, and <code>aarch64-darwin</code>.</p>

<h3 id="flakehub-notes">FlakeHub notes</h3>

<a href="https://flakehub.com/flake/chaotic-cx/nyx"><img alt="FlakeHub" src="https://img.shields.io/endpoint?url=https://flakehub.com/f/chaotic-cx/nyx/badge" /></a>

<p>Add chaotic to your <code>flake.nix</code>, make sure to use the rolling <code>*.tar.gz</code> to keep using the latest packages:</p>

<pre lang="nix"><code class="language-nix">
# flake.nix
{
  # ... description
  inputs = {
    # ... nixpkgs, home-manager, etc
    chaotic.url = "https://flakehub.com/f/chaotic-cx/nyx/*.tar.gz";
  };
  # ... outputs
}
</code></pre>

<p>Then follow one of the guides above.</p>

<h3 id="cachyos-notes">CachyOS notes</h3>

<p>A major selling point of using Chaotic-Nyx's downstream CachyOS kernels is that they achieve **kconfig parity** with the upstream CachyOS. Other flakes and Nixpkgs typically do not attempt to maintain this strict 1:1 configuration parity for their custom or downstream kernels.</p>

<pre lang="nix"><code class="language-nix">
# configuration.nix
{ config, pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  # other (optional) custom CachyOS packages that may be fit for your setup include:
  boot.zfs.package = pkgs.zfs_cachyos;
  hardware.nvidia.package = pkgs.nvidia_cachyos;
}
</code></pre>

<p>The default variant matches the upstream (at the time of writing, LTO+BORE), check the equivalent PKGBUILD variables in <code>pkgs/linux-cachyos/config-vars/cachyos-lto.json</code>. Here's an example using LTS:</p>

<pre lang="nix"><code class="language-nix">
# configuration.nix
{ config, pkgs, ... }:
{
  boot.kernelPackages = pkgs.linuxPackages_cachyos-lts;
  # other (optional) custom CachyOS packages that may be fit for your setup include:
  hardware.nvidia.package = pkgs.nvidia_cachyos-lts;
  boot.zfs.package = pkgs.zfs_cachyos; # Userspace package here, doesn't follow kernel variants.
}
</code></pre>

<p>We offer other variants: <code>hardened</code>, <code>lts</code>, <code>rc</code>, <code>server</code>, and <code>lto-znver4</code> (for AMD's Zen4 or superior). They all update individually. Plus a <code>gcc</code> that follows the default, in case Clang+LTO is causing you any trouble.</p>

<p>You may install the CachyOS kernel directly using the default modules and overlays with <code>pkgs.linuxPackages_cachyos</code>. Alternatively, use <code>chaotic.legacyPackages.x86_64-linux.linuxPackages_cachyos</code> if you would like to use the package directly without using modules and overlay.</p>

<p>Not all the variants have kernel modules pre-compiled. We would love to, but don't have enough resources.</p>

<p>CachyOS upstream doesn't support aarch64, due to the parity goal, we ignore it too.</p>

<p>One can validate the kconfig parity with <code>pkgs/linux-cachyos/conformance-test.sh</code>, you'll need to tweak the envvars. Please, open an issue if drifted.</p>

<h4>CachyOS x86-64 microarchitecture optimisations</h4>

<pre lang="nix"><code class="language-nix">
{ pkgs, ... }:
{
  boot.kernelPackages =
    pkgs.linuxPackages_cachyos.cachyOverride
      { cachyVars = pkgs.linuxPackages_cachyos.kernel.cachyConfig.cachyVars // { "_processor_opt" = "GENERIC_V3"; }; }
}
</code></pre>

<p>Use either <code>GENERIC_V2</code>, <code>GENERIC_V3</code>, <code>GENERIC_V4</code>, or <code>ZEN4</code>. We don't provide cache for these.</p>

<p>We support a few other variables from CachyOS' PKGBUILD in the <code>cachyVars</code> atttrset.</p>

<h4 id="using-sched-ext-schedulers">Using sched-ext schedulers</h4>

<p> From version 6.12 onwards, sched-ext support is officially available on the upstream kernel. You can use the latest kernel (<code>pkgs.linuxPackages_latest</code>) or our provided CachyOS kernel (<code>pkgs.linuxPackages_cachyos</code>). Not all variants of CachyOS support it.</p>

<p>Just add this to your configuration:</p>

<pre lang="nix"><code class="language-nix">
# configuration.nix
{
  boot.kernelPackages = pkgs.linuxPackages_cachyos;
  services.scx.enable = true; # by default uses scx_rustland scheduler
}
</code></pre>

<p> Then, reboot with the new configuration, check if the scheduler is running: </p>

<pre lang="text"><code class="language-text">
╰─λ systemctl status scx.service
</code></pre>

<p> If this is not working, check if the current kernel support <code>sched-ext</code> feature. </p>

<pre lang="text"><code class="language-text">
╰─λ ls /sys/kernel/sched_ext/
enable_seq  hotplug_seq  nr_rejected  root  state  switch_all
</code></pre>

<p> You can also manually start a scheduler like: </p>

<pre lang="text"><code class="language-text">
╰─λ sudo scx_rusty
21:38:53 [INFO] CPUs: online/possible = 24/32
21:38:53 [INFO] DOM[00] cpumask 00000000FF03F03F (20 cpus)
21:38:53 [INFO] DOM[01] cpumask 0000000000FC0FC0 (12 cpus)
21:38:53 [INFO] Rusty Scheduler Attached
</code></pre>

<p>You can choose a different scheduler too.</p>
<pre lang="nix"><code class="language-nix">
# configuration.nix
{
  services.scx.scheduler = "scx_rusty";
}
</code></pre>

<p>There are other scx_* binaries for you to play with, or head to <a href="https://github.com/sched-ext/scx" target="_blank">github.com/sched-ext/scx</a> for instructions on how to write one of your own.</p>

<h3 id="using-with-read-only-pkgs">Using with read-only pkgs</h3>

<p>If you use <code>nixpkgs.nixosModules.readOnlyPkgs</code> in your setup, you need to disable our overlay module, and import the cache-friendly overlay directly instead.</p>

<pre lang="nix"><code class="language-nix">
# flake.nix
{
  # ... description, inputs
  outputs = { nixpkgs, chaotic, ... }: {
    nixosConfigurations = {
      # ... other systems
      hostname = nixpkgs.lib.nixosSystem { # Replace "hostname" with your system's hostname
        modules = [
          nixpkgs.nixosModules.readOnlyPkgs
          # ... ./configuration.nix, ./hardware-configuration.nix, etc
          {
            nixpkgs.pkgs = import nixpkgs {
              system = "x86_64-linux";
              config = { allowUnfree = true; };
              overlays = [ chaotic.overlays.cache-friendly ]; # IMPORTANT
            };
            chaotic.nyx.overlay.enable = false; # IMPORTANT
          }
          chaotic.nixosModules.default # IMPORTANT
        ];
      };
    };
  };
}
</code></pre>

<h3 id="using-with-jovian">Using with Jovian</h3>

<p>We provide binary cache for most packages in <a href="https://github.com/Jovian-Experiments/Jovian-NixOS" target="_blank">Jovian NixOS</a>.</p>

<p>Remember to read all our <a href="#binary-cache-notes">Binary Cache notes</a>, and you <b>must follow jovian through chaotic</b> to avoid hash mismatches:</p>

<pre lang="nix"><code class="language-nix">
# flake.nix
{
  # ... description
  inputs = {
    # ... nixpkgs, home-manager, etc
    chaotic.url = "github:chaotic-cx/nyx/nyxpkgs-unstable";
    # no need to add jovian here, we vendor it
  };

  outputs = { nixpkgs, chaotic, ... }:
    let
      inherit (chaotic.vendored) jovian;
    in
    {
      nixosConfigurations = {
        steamdeck = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            jovian.nixosModules.default
            chaotic.nixosModules.default
            ./configuration.nix
            {
              # This entre { ... } is an example of what could be inside ./configuration.nix
              jovian.steam.enable = true;
              jovian.steam.autoStart = true;
              jovian.devices.steamdeck.enable = true;
            }
          ];
        };
      };
    };
}
</code></pre>

<h2 id="lists-of-options-and-packages">Lists of options and packages</h2>

<!-- cut here --><p>An always up-to-date list of all our options and packages is available at: <a href="https://www.nyx.chaotic.cx/#lists-of-options-and-packages">List page</a>.</p><!-- cut here -->

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

<h3>Building over the user's pkgs</h3>

<p>For cache reasons, Chaotic-Nyx now defaults to always use nixpkgs as provider of its dependencies.</p>

<p>If you need to change this behavior, set <code>chaotic.nyx.onTopOf = "user-pkgs";</code>. Be warned that you mostly won't be able to benefit from our binary cache after this change.</p>

<p>You can also disable our overlay entirely by configuring <code>chaotic.nyx.overlay.enable = false;</code>.</p>

<h2 id="criteria-for-new-packages">Criteria for new packages</h2>

<p>We'll only accept new packages given the following circumstances:</p>

<ul>
  <li>Package was rejected in Nixpkgs due to lack of stability or Nixpkgs cannot provide updates as fast as needed;</li>
  <li>A derivation for it already exists, working without IFD.</li>
</ul>

<h2 id="why-am-i-building-a-kernel-basic-cache-troubleshooting">Why am I building a kernel? Basic cache troubleshooting</h2>

<p>For starters, suppose you're using our <code>linuxPackages_cachyos</code> as the kernel and an up-to-date flake lock. Check if all these three hashes prompt the same:</p>

<pre lang="text"><code class="language-text">
╰─λ nix eval 'github:chaotic-cx/nyx/nyxpkgs-unstable#linuxPackages_cachyos.kernel.outPath'
"/nix/store/441qhriiz5fa4l3xvvjw3h4bps7xfk08-linux-6.8.7"

╰─λ nix eval 'chaotic#linuxPackages_cachyos.kernel.outPath'
"/nix/store/441qhriiz5fa4l3xvvjw3h4bps7xfk08-linux-6.8.7"

╰─λ nix eval '/etc/nixos#nixosConfigurations.{{HOSTNAME}}.config.boot.kernelPackages.kernel.outPath'
"/nix/store/441qhriiz5fa4l3xvvjw3h4bps7xfk08-linux-6.8.7"
</code></pre>

<p>If the second is different from the first, you're probably adding a <code>inputs.nixpkgs.follows</code> to <code>chaotic</code>, simply remove it.</p>

<p>If the third is different from the first, you're most likely using an overlay that's changing the kernel or one of its dependencies; check your <code>nixpkgs.overlays</code> config.</p>

<hr style="width: 50%; margin: 0 auto;">

<p>If they all match, and you're still rebuilding the kernel, copy the hash from the result above, then change it in the following <code>curl</code> command:</p>

<pre lang="text"><code class="language-text">
╰─λ curl -L 'http://nyx-cache.chaotic.cx/3w8ad8iysc2v0ic8m3ffrid4j7m20p27.narinfo'
StorePath: /nix/store/3w8ad8iysc2v0ic8m3ffrid4j7m20p27-libdrm-b8b7c57-bin
URL: nar/0529rfk9kp4ff0w0ljfa88mz46f8iq51sb020jdw7qb6z17n477m.nar.zst
Compression: zstd
NarHash: sha256:0529rfk9kp4ff0w0ljfa88mz46f8iq51sb020jdw7qb6z17n477m
NarSize: 550808
References: 57iz36553175g3178pvxjij8z5rcsd4n-glibc-2.42-61 zyiv5lp015g94xjw499wapk121qcarc1-libdrm-b8b7c57
Deriver: 79g0hvd6lmg76gyl7sqwvac38dxnlbg1-libdrm-b8b7c57.drv
Sig: nyx-cache.chaotic.cx:6q6x88p+CMjaa42DBYs7Fi4OYxrTj/nlpaK2BbHb68ke0TEKpXOaSUsCUybazLbv2snUWgA9jGs/E4NtJxp9CA==
</code></pre>

<p>If the command above fails without an 404, then you have an issue with your internet connection. If it fails with 404, then tag <code>pedrohlc</code> (Matrix, Telegram or GitHub), he really broke the cache.</p>

<p>If the command succeeds, and you're still building the cache, it can happen because of two things: (1) you might have tried to fetch said package before we deployed, then Nix will cache the 404 and won't try again; (2) you might have a misconfigured <code>/etc/nix/nix.conf</code> or outdated nix-daemon.</p>

<p>For the second one, check if it looks like this (the word “chaotic” should appear three times):</p>

<pre lang="text"><code class="language-text">
╰─λ grep chaotic /etc/nix/nix.conf
substituters = https://nyx-cache.chaotic.cx/ https://cache.nixos.org/
trusted-public-keys = cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY= nyx-cache.chaotic.cx:dJxTrgMC3V3cFfyIiBQDQorG6k1LsqurH/srpMSq7qk=
</code></pre>

<p>An outdated nix-daemon can happen when you change nix settings, then nixos-rebuilt your system, but you didn't restart the nix-daemon service. The easiest way to fix it is to reboot.</p>

<h2 id="special-thanks">Special Thanks</h2>

<ul>
  <li>The <a href="https://github.com/chaotic-cx/nyx/graphs/contributors" target="_blank">50 contributors</a>;</li>
  <li>Original sponsors: Silvan, Kai, Elite, and Keenan;</li>
  <li>lonerOrz for keeping <a href="https://github.com/lonerOrz/nyx-loner" target="_blank">a wonderful fork</a>;</li>
  <li>Everybody that provided feedback through Github, Telegram, and Matrix.</li>
</ul>
