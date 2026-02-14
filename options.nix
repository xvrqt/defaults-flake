{ lib, ... }: {
  options = {
    defaults = {
      packages = {
        remoteBuilds = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Use the remote builder";
        };
        buildRemotes = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Make your self available as a remote builder";
        };
        optimize = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Optimize the default packages for this machine.";
        };
        harden = lib.mkOption {
          type = lib.types.bool;
          default = true;
          description = "Harden the default packages for this machine.";
        };
      };
    };
  };
}
