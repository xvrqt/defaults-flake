{ pkgs, lib, ... }:
{
  # Enable NixOS Flakes
  nix = {
    settings.experimental-features = [
      "nix-command"
      "flakes"
    ];
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

  # Set your time zone.
  time.timeZone = lib.mkDefault "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";

  # Get specific with formatting
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

  # Run programs without nix-shell
  programs = {
    # Nix helper functions
    nh = {
      enable = true;
      flake = "/key/flake";
    };
    nix-index-database.comma.enable = lib.mkDefault true;
  };

  # Packages every system needs 
  environment = {
    # So we don't get stuck with a shitty editor
    variables = {
      # We use mkOverried 990 because NixOS be default sets a default value
      # (nano; priority 1000) to these environment variables 
      EDITOR = lib.mkOverride 990 "hx";
      VISUAL = lib.mkOverride 990 "hx";
    };
    # These packages are automatically available to all users
    systemPackages = [
      # Default text editor
      pkgs.helix
      # Pretty print system information upon shell login
      pkgs.hyfetch
    ];
    # Permissible login shells (sh is implicitly included)
    shells = lib.mkDefault [ pkgs.zsh ];
  };

  services = {
    nixos-cli = {
      enable = true;
      prebuildOptionCache = true;
      # config = {};
    };
  };

  # Allow sudoers to not invoke password
  security = {
    sudo = {
      enable = lib.mkDefault true;
      # Don't challenge memebers of 'wheel'
      wheelNeedsPassword = lib.mkDefault false;
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
        hashedPassword = "!";
        initialHashedPassword = "!";
      };
    };
  };
}
