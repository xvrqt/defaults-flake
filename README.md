# Defaults Flake

Sets sensible defaults for many options. These defaults remove cruft, add security, and conform to my personal flake ecosystem's assumptions more broadly. It is well commented, so I recommend reading the module, and copying what works for you - rather than using this flake directly.

## Installation

Add this flake to your NixOS Configuration list of modules flake inputs, and add its NixOS Module to the outputs:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs";
    defaults.url = "github:xvrqt/defaults-flake";
    # etc...
  };

  outputs = {defaults, ...} @ inputs: {
      nixos-configuration = nixpkgs.lib.nixosSystem {
        inherit pkgs;
        specialArgs = { inherit inputs; };
        modules = [
          defaults.nixosModules.default  # <-- Important Bit
          ./my-nix-configuration.nix
          # etc...
        ];
      };
  };
}
```

This will set up the defaults. There are no custom options, because you can simply override the defaults set in this flake if necessary.

## Utilities

There are several utility functions I also bundled in this flake which allow you to override CFLAGS when building `gcc` derivations.

```nix
# Some Module
{pkgs, inputs, ...}: let
  # Import the functions using your own instance of nixpkgs to avoid pulling in
  # yet another nixpkgs
  utils = inputs.defaults.lib {inherit pkgs;};
in
{
  environment.systemPackages = [
    # This will override the CFLAGS and return the new derivation
    # This will obviously have no effect on programs without CFLAGS but may
    # trigger a local build of the project instead of retrieving from cache
    # since it overrides the derivation
    #
    # Fastest cow talking this side of the Mississippi
    (utils.optimizeForThisMachine pkgs.cowsay)
  ];
}
```
