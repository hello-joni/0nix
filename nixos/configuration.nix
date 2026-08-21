{
  inputs,
  lib,
  config,
  pkgs,
  ...
}:
{
  # ------------------------------------------------------------
  # NIX CONFIG

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "26.05";

  imports = [
    # Shared modules
    ../modules/unfree.nix
  ];

  nixpkgs = {
    config = {
      # Unfree packages are handled with 0nix/modules/unfree.nix by declaring:
      # config.allowedUnfreePackages = [ "foo-pkg" "bar-pkg" ];
      allowUnfree = false;
    };
  };

  nix = {
    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Disable global registry
      flake-registry = "";
    };
    # Disable channels
    channel.enable = false;
  };

  # ------------------------------------------------------------
  # ACCOUNT ICON

  # Gajau monster icon resized and padded to 256x256 for the GNOME login screen.
  # Sets the icon via AccountsService activation script.
  system.activationScripts.account-icon.text = ''
    mkdir -p /var/lib/AccountsService/icons
    cp ${
      pkgs.runCommand "gajau-icon.png"
        {
          nativeBuildInputs = [ pkgs.imagemagick ];
        }
        ''
          convert ${
            builtins.fetchurl {
              url = "https://monsterhunterwiki.org/images/7/73/MHWI-Gajau_Icon.png";
              sha256 = "cECfwlJs1PbwvNszlxZ0TYEYufSdriCU8TxwQD2Z3Ds=";
            }
          } -resize 200x200 -background none -gravity center -extent 256x256+0-10 $out
        ''
    } /var/lib/AccountsService/icons/joni
    chmod 644 /var/lib/AccountsService/icons/joni

    cat > /var/lib/AccountsService/users/joni <<EOF
    [User]
    Icon=/var/lib/AccountsService/icons/joni
    SystemAccount=false
    EOF
  '';

  # ------------------------------------------------------------
  # SYSTEM CONFIG

  # Bootloader config
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Home Manager as a NixOS module
  home-manager.useUserPackages = true;
  home-manager.users.joni = import ../home-manager/home.nix;

  networking.hostName = "gajau";

  users.users = {
    joni = {
      # Shows on login page
      description = "Gajau";

      # Fish is entered via exec in fish.nix
      shell = pkgs.bashInteractive;

      # Change password with `passwd` and `sudo passwd root`
      initialPassword = "passwd";
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "video"
        "dialout" # serial port access (Tiny Tapeout FPGA demoboard)
        "plugdev" # Digilent test and measurement devices (Analog Discovery 2)
      ];
    };
  };

  # ------------------------------------------------------------
  # PACKAGES

  allowedUnfreePackages = [
    "waveforms" # Digilent Oscilloscope
    "adept2-runtime" # Digilent Oscilloscope
  ];

  environment.systemPackages = with pkgs; [
    pciutils
    file
    tree
    jq
    unzip
    zip
    vim
  ];

  # GNOME desktop
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # Fish shell: enables vendor completions and man-page completion generation
  programs.fish.enable = true;

  # Tailscale
  services.tailscale.enable = true;

  # Flatpak system daemon and system installation
  services.flatpak.enable = true;
}
