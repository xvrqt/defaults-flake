{ lib, pkgs, utils, ... }:
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
    ssh.package = lib.mkDefault (utils.compileTimeHardening pkgs.openssh);
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
      (utils.optimizeForThisMachine pkgs.helix)
      # Pretty print system information upon shell login
      (utils.optimizeForThisMachine pkgs.hyfetch)
    ];
    # Remove all other default packages so nothing sneaks in
    # Also, FUCK NANO
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
    auditd = {
      enable = lib.mkDefault true;
      settings = {
        # TODO default place is fine for now, but consider collating logs
        # onto a special dev or volume in the future
        # log_file = "<path>";
        # 
        # Number of log files to keep
        num_logs = lib.mkDefault 8;
        # Maximum logfile size, in MiB
        max_log_file = lib.mkDefault 32;
        # What to do when we're out of log files
        max_log_file_action = lib.mkDefault "rotate";
      };
    };
    audit = {
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

  # Users are typically added through the identities-flake
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
}
