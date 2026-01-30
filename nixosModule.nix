{ lib, pkgs, config, ... }:
let
  # Overrides a derivation to include new CFLAGS alongside existing CFLAGS
  # flags is a list of a strings representing the CFLAGS to be set
  optimizeWithFlags = pkg: flags:
    pkgs.lib.overrideDerivation pkg (old:
      let
        newflags = pkgs.lib.foldl' (acc: x: "${acc} ${x}") "" flags;
        oldflags =
          if (pkgs.lib.hasAttr "NIX_CFLAGS_COMPILE" old)
          then "${old.NIX_CFLAGS_COMPILE}"
          else "";
      in
      {
        NIX_CFLAGS_COMPILE = "${oldflags} ${newflags}";
      });

  # Ensure all possible optimizations for this machine
  optimizeForThisMachine = pkg:
    optimizeWithFlags pkg [
      # Optimize level 3 (highest level)
      "-O3"
      # Optimize using specific microcode and ISA implementations for this machine
      "-march=native"
      # No relative pointer index offets (Position Independent Code)
      "-fPIC"
    ];

  # Harden the code to make it less likely to be expoloited
  compileTimeHardening = pkg:
    optimizeWithFlags pkg [
      # Warn when printf/scanf don't use string literals
      "-Wformat"
      "-Wformat-security"
      "-Werror=format-security"
      # Add overwrite canaries to buffers greater than 4 bytes
      "-fstack-protector-strong"
      "--param ssp-buffer-size=4"
      # Add buffer overflow checks at compile and at runtime; no using %n in
      # string formatting functions (e.g. printf()) unless they are read only
      "-O2"
      "-D_FORTIFY_SOURCE=2"
      # No relative pointer index offets (Position Independent Code) and makes
      # ASLR possible
      "-fPIC"
      # Adds interger overflow checking to prevent errors
      "-fno-strict-overflow"
    ];

  # Optimize for Rust
  optimizeRustPkg = pkg:
    pkgs.lib.overrideDerivation pkg (old: {
      RUSTFLAGS =
        (old.RUSTFLAGS or "") + " -C target-cpu=native";
    });
in
{
  options = {
    defaults = {
      auditing = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable logging syscalls using autitd.";
      };
      packages = {
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

  config =
    let
      harden = pkg: (if config.defaults.packages.optimize then (compileTimeHardening pkg) else pkg);
      # I don't have any gcc programs, but you might
      optimizeC = pkg: (if config.defaults.packages.optimize then (optimizeForThisMachine pkg) else pkg);
      optimizeRust = pkg: (if config.defaults.packages.optimize then (optimizeRustPkg pkg) else pkg);
      editor = config.defaults.editor;
      auditCheck = config.defaults.auditing;
    in
    {
      nix = {
        settings = {
          # Enable NixOS Flakes
          experimental-features = [
            "nix-command"
            "flakes"
          ];
          # Only allow those with admin privileges invoke Nix commands
          allowed-users = [ "@wheel" ];
        };
        # Optimise the Nix-Store once a day
        optimise = lib.mkDefault {
          automatic = true;
          dates = [ "daily" ];
        };
        # Automatically Clean-out the Nix-Store once a day
        gc = lib.mkDefault {
          automatic = true;
          options = "--delete-older-than 30d";
          dates = "daily";
        };
      };
      # Only keep 10 generations maximum
      boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;

      # Timezone to the West Coast (Best Coast) by default
      time.timeZone = lib.mkDefault "America/Los_Angeles";

      # Select internationalisation properties.
      i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

      # Get specific with encoding
      i18n.extraLocaleSettings = lib.mkDefault {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };

      programs = {
        # Nix helper functions
        nh = {
          enable = lib.mkDefault true;
          # Where I always mount my flake
          flake = lib.mkDefault "/key/flake";
        };

        # Run programs without nix-shell
        # Usage: $ , cowsay "Hello"
        # It will install cowsay temporily, run the program in your shell, and then
        # remove it from your PATH again afterwards.
        nix-index-database.comma.enable = lib.mkDefault true;

        # Set the ssh package to be the hardened version of itself
        ssh.package = lib.mkDefault (harden pkgs.openssh);

        # Ensure a shell is enabled
        zsh.enable = lib.mkDefault true;
      };

      # Packages every system needs 
      environment = {
        # So we don't get stuck with a shitty editor
        variables = {
          # We use mkOverried 990 because NixOS be default sets a default value
          # (nano; priority 1000) to these environment variables 
          EDITOR = lib.mkOverride 990 "hx";
          VISUAL = lib.mkOverride 990 "hx";
          SUDO_EDITOR = lib.mkOverride 990 "hx";
        };
        # These packages are automatically available to all users
        systemPackages = [
          # Default text editor
          (optimizeRust pkgs.helix)
          # Pretty print system information upon shell login
          (optimizeRust pkgs.hyfetch)
        ];
        # Remove all other default packages so nothing sneaks in
        defaultPackages = lib.mkDefault [ ];
        # Permissible login shells (sh is implicitly included)
        shells = lib.mkDefault [ pkgs.zsh ];
      };

      services = {
        # Useful for the option search
        # Usage: nixos option -f <path-to-your-system-flake>
        # Allows you to see what the final value of your configuration options are
        nixos-cli = {
          enable = lib.mkDefault true;
          # Builds option cache on system rebuild
          prebuildOptionCache = lib.mkDefault true;
          # config = {};
        };
      };

      # Allow sudoers to not require a password
      security = {
        sudo = {
          enable = lib.mkDefault true;
          # Don't challenge memebers of 'wheel'
          wheelNeedsPassword = lib.mkDefault false;
        };
        # Enable Linux Kernel Auditing
        auditd = lib.mkIf auditCheck {
          enable = lib.mkDefault true;
          settings = {
            # Number of log files to keep
            num_logs = lib.mkDefault 8;
            # Maximum logfile size, in MiB
            max_log_file = lib.mkDefault 32;
            # What to do when we're out of log files
            max_log_file_action = lib.mkDefault "rotate";
          };
        };
        audit = lib.mkIf auditCheck {
          enable = lib.mkDefault true;
          # -a exit,always -> Run audit when syscall is loaded, no matter what
          # -F arch=b64 -> Only log syscalls made by 64bit processes
          # -S execve -> Only monitor the execve system call flag
          # Typically invoked by a shell, this monitors every attempt for a
          # 64bit process to execute another program
          rules = lib.mkDefault [
            "-a exit,always -F arch=b64 -S execve"
          ];
        };
      };

      # Here is sensible, locked down root user as a default though
      users = {
        users = {
          root = lib.mkDefault {
            # Default Shell
            shell = pkgs.zsh;
            # Added to the list of sudoers
            extraGroups = [ "networkmanager" "wheel" ];
            # Disable logging in as root
            hashedPassword = lib.mkDefault "!";
            initialHashedPassword = lib.mkDefault "!";
          };
        };
      };
    };
}
