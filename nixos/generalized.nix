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
      description = "If to enable Wayland as display protocol with sway.";
    };

    graphical = mkOption {
      type = types.bool;
      default = cfg.wayland || cfg.xorg;
      description = "If to install graphical applications. Automatically enabled if you enable a display protocol.";
    };

    hidpi = mkOption {
      type = types.bool;
      default = false;
      description = "If this system has a high display resolution on a relatively small surface. Causes most elements to be scaled up and a larger font size in the console.";
    };

    audio = mkOption {
      type = types.bool;
      default = false;
      description = "If this system should have PipeWire with compatability plugins installed and running.";
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

    pkgs-unstable = mkOption {
      type = types.pkgs;
      default = import <nixos-unstable> {
        config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) [
          "nvidia-x11"
        ];

        overlays = [
          (final: prev: {
            neovim-nightly-unwrapped = final.neovim-unwrapped.overrideAttrs {
              version = "0.10.0-nightly";
              src = pkgs.fetchFromGitHub {
                owner = "neovim";
                repo = "neovim";
                rev = "0211f889b9538f7df5fbcb06273d273fb071efff";
                hash = "sha256-JeZWpcCczEwIw3wX3zUFN0kM/y5cj5PrlO59ckUdGyE=";
              };
            };
          })
          (final: prev: if (cfg.videoDriver == "nvidia" && cfg.wayland) then {
            # blatantly taken from https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
            wlroots = prev.wlroots.overrideAttrs (finalAttrs: prevAttrs: {
              postPatch = (prev.postPatch or "") + ''
                substituteInPlace render/gles2/renderer.c --replace "glFlush();" "glFinish();"
              '';
            });
          } else {})
          (final: prev: if cfg.profileGuided then {
            linuxZenFast = prev.linuxPackagesFor (prev.linuxKernel.kernels.linux_zen.override {
              stdenv = pkgs.fastStdenv;
            });
          } else {})
        ];
      };
      description = "From where to pull unstable packages.";
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
        then cfg.pkgs-unstable.linuxZenFast
        else cfg.pkgs-unstable.linuxKernel.packages.linux_zen
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

    hardware = {
      pulseaudio.enable = false; # handled by pipewire-pulse instead
      opengl = {
        enable = true;
        extraPackages = with pkgs;
          if cfg.videoDriver == "intel"
            then [mesa.drivers intel-media-driver intel-compute-runtime]
          else if cfg.videoDriver == "nvidia"
            then [config.boot.kernelPackages.nvidia_x11]
          else [];
      };

      nvidia = if cfg.videoDriver == "nvidia"
        then {
          modesetting.enable = true;
          open = true;
        }
        else {};
    };

    networking = {
      hostName = cfg.hostName;
      wireless.iwd.enable = cfg.wireless.wlan;
      networkmanager.enable = false;
    };
    time.timeZone = "Europe/Berlin";

    i18n.defaultLocale = "en_US.UTF-8";

    console = {
      font =
        if cfg.hidpi
        then "ter-132b"
        else "Lat2-Terminus16";

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
              ++ (if cfg.graphical then ["input" "video" "audio"] else [])
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

      # audio server
      pipewire = {
        enable = cfg.audio;
        alsa.enable = true;
        alsa.support32Bit = true;
        pulse.enable = true;
        jack.enable = true;
        wireplumber.enable = true;
      };
    };

    environment = {
      systemPackages = with pkgs; [
        curl rsync rclone magic-wormhole-rs
        fd ripgrep
        file pv
        ffmpeg mpv jq unzip zip
        alacritty
        btop
      ]
      ++ (if cfg.xorg then [xclip] else [])
      ++ (if cfg.wayland then [
        fuzzel waybar mako grim slurp swappy hyprpicker gammastep
        swaybg swaylock wl-clipboard
        waypipe
      ] else [])
      ++ (if cfg.graphical then [
        # themes
        adapta-gtk-theme adapta-kde-theme
        breeze-icons volantes-cursors
      ] else []);

      sessionVariables = {
        TYPST_FONT_PATHS =
          if config.fonts.fontDir.enable
          then "/run/current-system/sw/share/X11/fonts"  # not sure if I should upstream this
          else "";
      };

      shellAliases = {
        l = "ls -lh --group-directories-first --sort ext";
        ll = "l -a";
        c = "clear";
        help = "man";
        reb = "sudo nixos-rebuild switch";
        rebb = "sudo nixos-rebuild boot";
      };

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

      sway = {
        enable = cfg.wayland;
        package =
          let
            # sway behaves kind of weird on unstable
            # flipped screen and unusable flickering on QEMU (elusive)
            # huge performance drops on intel iGPUs
            conditionalSwayPackage =
              if builtins.elem cfg.videoDriver ["virtio" "intel"]
              then pkgs.sway
              else cfg.pkgs-unstable.sway;
          in
            conditionalSwayPackage.override {
              extraSessionCommands = ''
                export PATH=$HOME/zukunftslosigkeit/scripts:$PATH
                export SDL_VIDEODRIVER=wayland
                export QT_QPA_PLATFORM=wayland-egl
                export QT_WAYLAND_FORCE_DPI=physical
                export ECORE_EVAS_ENGINE=wayland_egl
                export ELM_ENGINE=wayland_egl
                export _JAVA_AWT_WM_NONREPARENTING=1
              '';

              extraOptions = if cfg.videoDriver == "nvidia"
                then ["--unsupported-gpu"]
                else [];

              withGtkWrapper = true;
              isNixOS = true;
            };
      };

      xwayland.enable = false;  # enabled by default by sway, but I don't need it

      # shell
      zsh = {
        enable = true;
        autosuggestions.enable = true;
        promptInit = ''
          if [[ $HOST == "elusive" ]]; then
            PROMPT=' %D{%H %M} %F{2}%(!.#.=)%f '
          else
            PROMPT=' %D{%H %M} %F{6}%(!.#.=)%f '
          fi
          RPROMPT='%(?..%F{1}%?%f) %F{5}%~%f %F{4}@%M%f'
        '';
      };
    };

    xdg.portal.enable = lib.mkForce false;
    qt = {
      enable = true;
      platformTheme = "qt5ct";
    };

    nix.settings.auto-optimise-store = true;
    nixpkgs.overlays = [
      (final: prev: if cfg.profileGuided then {
        godot_4 = prev.godot_4.override {
          stdenv = pkgs.fastStdenv;
        };
      } else {})
    ];
  };
}
