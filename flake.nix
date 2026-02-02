{
  inputs = {
    # Used to keep the other inputs in lock-step
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Used to track options
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, nix-index-database, ... }:
    let
      forAllSystems = function:
        nixpkgs.lib.genAttrs [
          "x86_64-linux"
          "aarch64-linux"
        ]
          (system: function nixpkgs.legacyPackages.${system});
    in
    {

      nixosModules = forAllSystems
        (pkgs:
          let
            lib = pkgs.lib;
          in
          {
            default = { config, ... }: {
              imports = [
                nix-index-database.nixosModules.nix-index
                (import ./nixosModule.nix {
                  inherit lib pkgs config;
                })
              ];
            };
          });
    };
}
