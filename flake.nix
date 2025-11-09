{
  inputs = {
    # Used to keep the other inputs in lock-step
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable-small";

    # Nicer rebuild utility
    nix-cli.url = "github:nix-community/nixos-cli";
    nix-cli.inputs.nixpkgs.follows = "nixpkgs";

    # Used to track 
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";

    # My flake utils
    flake-utils = {
      url = "git+https://git.irlqt.net/crow/flake-utils";
      flake = false;
    };

  };
  outputs =
    { nix-cli, flake-utils, nix-index-database, ... }:
    {
      nixosModules = {
        default = { lib, pkgs, ... }:
          let
            utils = (import "${flake-utils}/default.nix" { inherit pkgs; });
          in
          {
            imports = [
              nix-cli.nixosModules.nixos-cli
              nix-index-database.nixosModules.nix-index
              (import ./nixosModule.nix { inherit lib pkgs utils; })
            ];
          };
      };
    };
}
