---
title: Flake-based recipe for offline dev shells in NixOS
tags: offline, nix, nixos, flake, bash, tutorial, devops, blog
reminder: nix-bread.png
...

[blog]: https://github.com/jefdaj/cryptoisland/tree/master

I first fell in love with Nix when my mother used to make home cooked meals back on the family farm.
The smell of fresh bread would waft from the kitchen out onto the porch,
gently reminding me to look up from my laptop. I noticed the grass and the insects, and the lazy sound of a plane overhead. Sunlight slanted sideways now, illuminating the garden. I'd been struggling with my vim config all afternoon.
"Just a minute, mom!" I would yell.
"I've almost got this infinite recursion bug figured out!"

Just kidding... mostly.
Anyway here's my recipe for homemade named shells like `cryptoisland-shell`.
I'll illustrate it with [the code for this blog][blog],
but it should work for any nix shell.

The main benefit is that after a `nixos-rebuild` you can work on any of your repos without a network connection. It also makes it easier to update nixpkgs everywhere at once, and lets you garbage collect more aggressively without re-fetching some of the packages later.

# Usage

You can generally stay offline as long as you don't update nixpkgs or add new programs.

Rebuild the OS after updating one of your flakes:

~~~{ .txt }
# cd /etc/nixos
# nix flake lock --update-input cryptoisland
# nixos-rebuild switch
~~~

Use the named dev shell:

~~~{ .txt }
$ cd ~/cryptoisland
$ cryptoisland-shell
$ ./build.sh # or whatever
~~~

# Main NixOS flake

There's a lot of line noise here, as usual with flakes. But basically:

1. Add your repo as an input. You can skip following the top level nixpkgs input if the repo has more specific requirements, and you can use a URL instead of a local path.
2. Add the `wrapperScript` output to your system packages list.

~~~{ .nix }
# /etc/nixos/flake.nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-23.11";

    # the part we're interested in:
    cryptoisland = {
      url = path:/home/jefdaj/cryptoisland;
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

  # remember to add your flake to the inputs
  outputs = {self, nixpkgs, cryptoisland}@inputs: {
    nixosConfigurations = {
      myhostname = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          # see next section
          ./configuration.nix
        ];
      };
  };
}
~~~

~~~{ .nix }
# /etc/nixos/configuration.nix
# this is a standard "old style" NixOS config imported into the flake
{ config, pkgs, lib, inputs, ... }:
{
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  environment.systemPackages = with pkgs; [

    # our offline dev shells
    # don't forget to `nix flake lock --update-input` each of these after working on them
    inputs.cryptoisland.packages."${pkgs.system}".wrapperScript

  ];

  # ... rest of config here ...
}

~~~

# Flake per repo

All you need for this recipe are `devShell` and `wrapperScript` outputs.
The rest of the flake can be formatted differently.

<!-- TODO link to complete flake on github -->

~~~{ .nix }
# /home/jefdaj/cryptoisland/flake.nix
{
  description = "cryptoisland.blog dev shell";
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-unstable;
  };
  outputs = {self, nixpkgs}:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in rec {
      packages."${system}".default = packages."${system}".wrapperScript;
      packages."${system}".wrapperScript = { ... }; # see below
      devShells."${system}".default      = { ... }; # see below
  };
}
~~~

## wrapperScript

This is the unique part. It's a little ugly but reliable.

~~~{ .nix }
packages."${system}".wrapperScript =
  let
    shell = devShells."${system}".default;
  in
    pkgs.writeScriptBin "cryptoisland-shell" ''
      #!/usr/bin/env bash
      export PATH=${pkgs.lib.makeBinPath shell.buildInputs}:$PATH
      ${shell.shellHook}
      ${pkgs.bashInteractive}/bin/bash $@
    '';
~~~

## devShell

Set this up however you normally would.
It's a regular flake-based dev shell.

The only gotcha is that if you add fields to the `mkShell` call,
you might also need to duplicate them in the wrapper script above.
That can often be avoided by moving them inside `shellHook`.

~~~{ .nix }
devShells."${system}".default =
  let
    myGhc = pkgs.haskellPackages.ghcWithPackages (ps: with ps; [
      bytestring
      hakyll
      hakyll-images
      hakyll-sass
      filepath
      pandoc
      MissingH
      hjsmin
      text
      language-javascript
      aeson
    ]);
  in
    pkgs.mkShell {
      buildInputs = with pkgs; [
        myGhc
        rsync
        graphviz
      ];
      shellHook = ''
        export LOCALE_ARCHIVE="${pkgs.glibcLocales}/lib/locale/locale-archive"
      '';
    };
~~~

You can still use this the normal flakes way too, via `nix develop`.
Just remember that if you have a different nixpkgs input in the repo vs your NixOS config,
it'll rebuild the dependencies.
