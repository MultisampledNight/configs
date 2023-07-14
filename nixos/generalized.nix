# Help is available in the configuration.nix(5) man page and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;
in {
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

    externalInterface = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Which interface is designated to be exposed to the outside world.";
    };

    ssd = mkOption {
      type = types.bool;
      default = false;
      description = "If to enable services like fstrim for automatic SSD maintenace.";
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

    graphical = mkOption {
      type = types.bool;
      default = cfg.wayland || cfg.xorg;
      description = "If to install graphical applications. Automatically enabled if you enable a display protocol.";
    };

    profileGuided = mkOption {
      type = types.bool;
      default = false;
      description = "If to compile a few packages locally and adjusted to this CPU for better perfomance. Note that this will inherently make this configuration irreproducable on a platform that is only slightly different.";
    };

    videoDriver = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "What video driver to use for Xorg. Only in effect on development setups.";
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

    gaming = mkOption {
      type = types.bool;
      default = false;
      description = "If you are the type of person which is colloquially referred to as gamer. Only in effect on non-server setups.";
    };

    videos = mkOption {
      type = types.bool;
      default = false;
      description = "If you want to record and edit videos. Only in effect on non-server setups.";
    };
  };

  config = {
    boot = {
      loader = {
        systemd-boot = {
          enable = true;
          editor = false;
          consoleMode = "auto";
          configurationLimit = 256;
        };
        grub.enable = false;
        efi.canTouchEfiVariables = true;
      };

      kernelPackages = mkDefault (
        if cfg.profileGuided
        then pkgs.linuxZenFast
        else pkgs.linuxKernel.packages.linux_zen
      );
    };

    console.colors = [
      "212224" # black
      "ff9365" # red
      "11d396" # green
      "c7b700" # yellow
      "00c7f7" # blue
      "fa86ce" # magenta
      "aaa9ff" # cyan
      "b6b3b4" # white
      "7f7dcc" # bright black aka grey
      "ff9365" # bright red
      "11d396" # bright green
      "c7b700" # bright yellow
      "00c7f7" # bright blue
      "fa86ce" # bright magenta
      "aaa9ff" # bright cyan
      "b6b3b4" # bright white
    ];

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
      mutableUsers = mkDefault true; # needed for passwd changes to persist

      users =
        if cfg.forMulti then {
          multisn8 = {
            isNormalUser = true;
            extraGroups =
              ["wheel"]
              ++ (if cfg.graphical then ["input"] else [])
              ++ (if config.programs.adb.enable then ["adbusers"] else []);
            shell = pkgs.zsh;
          };
        } else {};
    };

    services = {
      fstrim.enable = cfg.ssd;

      openssh = {
        enable = cfg.ssh;
        startWhenNeeded = true;

        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
        };
      };
    };

    environment = {
      systemPackages = with pkgs; [
        curl rsync magic-wormhole-rs
        fd ripgrep
        file pv
        ffmpeg mpv jq unzip zip
        alacritty
        btop
      ];

      sessionVariables = {
        TYPST_FONT_PATHS =
          if config.fonts.fontDir.enable
          then "/run/current-system/sw/share/X11/fonts"  # not sure if I should upstream this
          else "";
      };

      interactiveShellInit = ''
        alias l='ls -lh --group-directories-first --sort ext'
        alias ll='l -a'
        alias c='clear'
        alias help='man'
      '';

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
          RPROMPT='%(?..%F{1}%?%f) %F{5}%~%f %F{4}@%M%f'
        '';
      };
    };

    nix.settings.auto-optimise-store = true;
  };
}
