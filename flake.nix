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

    # Used to generate per-system modules
    wrapper.url = "github:numtide/flake-utils";
  };

  outputs =
    { nix-cli, nixpkgs, wrapper, nix-index-database, ... }:
    wrapper.lib.eachDefaultSystem
      (system: {
        nixosModules =
          {
            default = { lib, config, ... }:
              let
                pkgs = nixpkgs.legacyPackages.${system};
              in
              {
                imports = [
                  nix-cli.nixosModules.nixos-cli
                  nix-index-database.nixosModules.nix-index
                  (import ./nixosModule.nix { inherit lib pkgs config; })
                ];
              };
          };
      });
}
