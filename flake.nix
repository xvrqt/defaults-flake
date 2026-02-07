{
  inputs = {
    # Used to keep the other inputs in lock-step
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    # Used to track options
    nix-index-database.url = "github:nix-community/nix-index-database";
    nix-index-database.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { nixpkgs, nix-index-database, ... }: {
      nixosModules.default = { pkgs, config, ... }:
        let
          pinnedPkgs = nixpkgs.legacyPackages.${pkgs.system};
        in
        {
          imports = [
            nix-index-database.nixosModules.nix-index
            (import ./nixosModule.nix {
              inherit config;
              pkgs = pinnedPkgs;
            })
          ];
        };
    };
}
