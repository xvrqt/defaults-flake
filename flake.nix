{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };
  outputs =
    { nix-index-database, ... }: {
      nixosModules = {
        default = { lib, pkgs, config, ... }:
          {
            imports = [
              nix-index-database.nixosModules.nix-index
              (import ./nixosModule.nix { inherit lib pkgs config; })
            ];
          };
      };
    };
}
