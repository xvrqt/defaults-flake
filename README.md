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
          defaults.nixosModules.${system}.default  # <-- Important Bit
          ./my-nix-configuration.nix
          # etc...
        ];
      };
  };
}
```

## Options

There are three options, which can you set using the following NixOS module.

```nix
{
  defaults = {
    # Whether or not to enable system wide auditing.
    # Defaults to FALSE. I only enable it on servers.
    auditing = false;

    packages = {
      # Whether to recompile your editor and hyfetch
      # Defaults to TRUE.
      optimize= true;
      # Whether to recompile openssh with hardening options
      # Defaults to TRUE.
      hardening = true;
    };
  };
}
```
