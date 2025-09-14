{
  inputs = {
    # Used to keep the other inputs in lock-step
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    nix-cli.url = "github:nix-community/nixos-cli";
    nix-cli.inputs.nixpkgs.follows = "nixpkgs";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    { nix-cli, nix-index-database, ... }: {
      nixosModules = {
        default = { lib, pkgs, config, ... }:
          {
            imports = [
              nix-cli.nixosModules.nixos-cli
              nix-index-database.nixosModules.nix-index
              (import ./nixosModule.nix { inherit lib pkgs config; })
            ];
          };
      };

      lib = import ./utils.nix;
    };
}
