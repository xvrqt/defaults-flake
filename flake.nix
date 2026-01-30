{
  inputs = {
    # Used to keep the other inputs in lock-step
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Nicer rebuild utility
    nix-cli.url = "github:nix-community/nixos-cli";
    nix-cli.inputs.nixpkgs.follows = "nixpkgs";

    # Used to track options
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # My flake utils, used for hardening and optimizing
    flake-utils = {
      url = "github:xvrqt/flake-utils/blog";
      flake = false;
    };

    # Used to generate per-system modules
    wrapper.url = "github:numtide/flake-utils";
  };

  outputs =
    { nix-cli, flake-utils, wrapper, nixpkgs, nix-index-database, ... }: {
      nixosModules = {
        default = { lib, config, ... }:
          wrapper.lib.eachDefaultSystem (system:
            let
              pkgs = nixpkgs.legacyPackages.${system};
              utils = (import "${flake-utils}/default.nix" { inherit pkgs; });
            in
            {
              imports = [
                nix-cli.nixosModules.nixos-cli
                nix-index-database.nixosModules.nix-index
                (import ./nixosModule.nix { inherit lib pkgs utils config; })
              ];
            });
      };
    };
}
