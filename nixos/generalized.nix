# Help is available in the configuration.nix(5) man page and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;
in
{
  options.generalized = {
    hostName = mkOption {
      type = types.strMatching
        "^$|^[[:alnum:]]([[:alnum:]_-]{0,61}[[:alnum:]])?$";
      default = "inconsistent";
      description = "The networking hostname of this system.";
    };

    layout = mkOption {
      type = types.str;
      default = "bone";
      description = "What keyboard layout to use on the Linux console and
      in graphical environments.";
    };

    wireless.wlan = mkOption {
      type = types.bool;
      default = true;
      description = "If to enable wireless services through iwd and iwctl.";
    };

    ssh = mkOption {
      type = types.bool;
      default = false;
      description = "If to expose an OpenSSH server.";
    };

    xorg = mkOption {
      type = types.bool;
      default = false;
      description = "If to enable Xorg as display protocol with i3. Only in effect on non-server setups.";
    };

    wayland = mkOption {
      type = types.bool;
      default = false;
      description = "If to enable Wayland as display protocol with sway. Only in effect on non-server setups.";
    };

    profileGuided = mkOption {
      type = types.bool;
      default = false;
      description = "If to compile a few packages locally and adjusted to this CPU for better perfomance. Note that this will inherently make this configuration irreproducable on a platform that is only slightly different.";
    };

    videoDriver = mkOption {
      type = types.str;
      default = "intel";
      description = "What video driver to use for Xorg. Only in effect on non-server setups.";
    };

    forMulti = mkOption {
      type = types.bool;
      default = true;
      description = "If an account for Multi should be added.";
    };

    forTheGeneralPublic = mkOption {
      type = types.bool;
      default = false;
      description = "If this system should stay usable to the general public, by forcing common layouts and installing common desktop environments. Setting this to `true` implicitly overrides `layout`.";
    };

    videos = mkOption {
      type = types.bool;
      default = false;
      description = "If you want to record and edit videos. Only in effect on non-server setups.";
    };

    gaming = mkOption {
      type = types.bool;
      default = false;
      description = "If you are the type of person which is colloquially referred to as gamer. Only in effect on non-server setups.";
    };
  };

  config = {
    boot = {
      loader = {
        grub = {
          device = "nodev";
          efiSupport = true;
        };

        efi.canTouchEfiVariables = true;
      };
    };

    networking = {
      hostName = cfg.hostName;
      wireless.iwd.enable = cfg.wireless.wlan;
      networkmanager.enable = false;
    };
    time.timeZone = "Europe/Berlin";

    i18n.defaultLocale = "en_US.UTF-8";

    console = {
      font = mkDefault "Lat2-Terminus16";
      keyMap = if cfg.forTheGeneralPublic then "de" else cfg.layout;
    };

    users = {
      defaultUserShell = pkgs.zsh;
      mutableUsers = true; # needed for passwd changes to persist

      users = {
        multisn8 = {
          isNormalUser = true;
          extraGroups = ["wheel"] ++ (if cfg.wayland || cfg.xorg then ["input"] else []);
          shell = pkgs.zsh;
          packages = with pkgs; [zoxide];
        };
      };
    };

    services = {
      openssh = {
        enable = cfg.ssh;
        startWhenNeeded = true;

        settings = {
          passwordAuthentication = false;
          kbdInteractiveAuthentication = false;
          permitRootLogin = "no";
        };
      };
    };

    environment = {
      systemPackages = with pkgs; [
        curl rsync magic-wormhole-rs
        fd ripgrep
      ];

      gnome.excludePackages = with pkgs.gnome; [cheese epiphany geary tali iagno hitori atomix evince];
      shells = with pkgs; [bashInteractive zsh];
    };

    programs = {
      git = {
        enable = true;
        config = {
          init.defaultBranch = "main";
          commit.gpgsign = true;
          core = {
            pager = "nvim -R";
            editor = "nvim";
          };
          color.pager = "off";
        };
      };

      neovim = {
        enable = true;
        vimAlias = true;
        viAlias = true;
      };

      # shell
      zsh = {
        enable = true;
        autosuggestions.enable = true;
        promptInit = ''
          PROMPT=' %D{%H %M} %F{6}%(!.#.=)%f '
          RPROMPT='%F{5}%~%f %F{4}@%M%f'
        '';
      };
    };
  };
}
