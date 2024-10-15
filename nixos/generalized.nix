# Help is available in the configuration.nix(5) man page and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;

  indent = strings.replicate 7 " ";

  nixpkgsFromCommit = { rev, hash, opts ? {} }:
    let
      tree = pkgs.fetchzip {
        name = "nixpkgs-${rev}";
        url = "https://github.com/nixos/nixpkgs/archive/${rev}.tar.gz";
        hash = hash;
      };
    in
      import tree opts;

  # see https://en.wikipedia.org/wiki/ANSI_escape_code
  # why they are exactly here? good question, had no other place to put them
  # if anyone has an idea on how to escape this in nix, let me know
  esc = "";
  csi = params: op: esc + "[" + params + op;

  sgr = n: csi (toString n) "m";
  cha = n: csi (toString n) "G";
  reset = "${esc}(B" + (csi "" "m");

  fg = idx: sgr (30 + idx);

  query = "${fg 4}>${reset}";
  error = "${fg 1}!${reset}";
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

    cpuVendor = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "What microcode updates to install.";
    };

    baremetal = mkOption {
      type = types.bool;
      default = true;
      description = ''
        If this machine runs directly on real hardware.
        If that is the case, firmware update and other hardware maintenance helpers are installed.
      '';
    };

    wireless.wlan = mkOption {
      type = types.bool;
      default = cfg.baremetal;
      description = "If to enable wireless services through iwd and iwctl.";
    };
    wireless.bluetooth = mkOption {
      type = types.bool;
      default = cfg.baremetal;
      description = "If to enable bluetooth.";
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

    gaming = mkOption {
      type = types.bool;
      default = false;
      description = "If you are the type of person which is colloquially referred to as gamer. Only in effect on non-server setups.";
    };

    multimedia = mkOption {
      type = types.bool;
      default = false;
      description = "If you want to record, produce and edit videos, music and audio. Only in effect on non-server setups.";
    };

    pkgs-unstable = mkOption {
      type = types.pkgs;
      default = import <nixos-unstable> {
        config = {
          allowUnfreePredicate = pkg: (
            (builtins.elem (lib.getName pkg) [
              "nvidia-x11"
              "nvidia-settings"
              "vimplugin-treesitter-grammar-cuda_merged"
              "blender"
              # those below are all just for CUDA it's so joever
              "libnpp"
            ]) || (
              any
                (prefix: hasPrefix prefix (lib.getName pkg))
                ["cuda" "libcu" "libnv"]
            )
          );
        };

        overlays = [
          (final: prev: if cfg.profileGuided then {
            godot_4 = prev.godot_4.override {
              stdenv = final.fastStdenv;
            };
          } else {})
          (final: prev: if cfg.profileGuided then {
            linuxZenFast = prev.linuxPackagesFor (prev.linuxKernel.kernels.linux_zen.override {
              stdenv = final.fastStdenv;
            });
          } else {})
          (final: prev: if (cfg.videoDriver == "nvidia" && cfg.wayland) then {
            # blatantly taken from https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
            wlroots = prev.wlroots.overrideAttrs (finalAttrs: prevAttrs: {
              postPatch = (prev.postPatch or "") + ''
                substituteInPlace render/gles2/renderer.c --replace "glFlush();" "glFinish();"
              '';
            });
          } else {})
          (final: prev: if (cfg.videoDriver == "nvidia") then {
            blender = prev.blender.override {
              cudaSupport = true;
            };
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
          enable = cfg.baremetal;
          editor = false;
          consoleMode = "auto";
          configurationLimit = 256;
        };
        grub.enable = false;
        efi.canTouchEfiVariables = cfg.baremetal;
      };

      kernelPackages = mkDefault (
        if cfg.profileGuided
        then cfg.pkgs-unstable.linuxZenFast
        else cfg.pkgs-unstable.linuxKernel.packages.linux_zen
      );

      tmp.cleanOnBoot = true;
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

      cpu.intel.updateMicrocode = cfg.cpuVendor == "intel";
      cpu.amd.updateMicrocode = cfg.cpuVendor == "amd";

      bluetooth.enable = cfg.wireless.bluetooth;

      opengl = {
        enable = true;
        driSupport = true;
        driSupport32Bit = true; # :clueless:
        extraPackages = with pkgs;
          if cfg.videoDriver == "intel"
            then [mesa.drivers intel-media-driver intel-compute-runtime]
          else if cfg.videoDriver == "nvidia"
            then [config.hardware.nvidia.package]
          else [];
        extraPackages32 =
          if cfg.videoDriver == "nvidia"
            then [config.hardware.nvidia.package.lib32]
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
        then null
        else "Lat2-Terminus16";

      keyMap = cfg.layout;
    };

    users = {
      defaultUserShell = pkgs.zsh;

      users.multisn8 = {
        isNormalUser = true;
        extraGroups =
          ["wheel" "plugdev" "antisuns" "kvm" "scanner" "lp"]
          ++ (if cfg.graphical then ["input" "video" "audio"] else [])
          ++ (if config.programs.adb.enable then ["adbusers"] else []);
        shell = pkgs.zsh;
      };

      groups = {
        plugdev = {};
      };
    };

    services = {
      fstrim.enable = cfg.ssd;
      fwupd.enable = cfg.baremetal;

      displayManager.enable = lib.mkForce false;
      xserver.displayManager.lightdm.enable = lib.mkForce false;

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
        alsa.enable = cfg.audio;
        pulse.enable = cfg.audio;
        jack.enable = cfg.audio;
        wireplumber.enable = cfg.audio;

        alsa.support32Bit = true;
      };

      udev.extraRules = ''
        # Quest 1
        SUBSYSTEM=="usb", ATTR{idVendor}=="2833", ATTR{idProduct}=="0186", MODE="0666", GROUP="plugdev"

        # Device rules for Intel RealSense devices (D405)
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5b", MODE:="0666", GROUP:="plugdev"

        # Intel RealSense recovery devices (DFU)
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0ab3", MODE:="0666", GROUP:="plugdev"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0adb", MODE:="0666", GROUP:="plugdev"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0adc", MODE:="0666", GROUP:="plugdev"
        SUBSYSTEMS=="usb", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b55", MODE:="0666", GROUP:="plugdev"

        KERNEL=="iio*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5b", MODE:="0777", GROUP:="plugdev", RUN+="${lib.getBin pkgs.bash} -c 'chmod -R 0777 /sys/%p'"
        DRIVER=="hid_sensor*", ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5b", RUN+="${lib.getBin pkgs.bash} -c 'chmod -R 0777 /sys/%p && chmod 0777 /dev/%k'"
      '';

      system76-scheduler.enable = true;
    };

    environment = {
      systemPackages = with pkgs; [
        curl rsync rclone magic-wormhole-rs
        efibootmgr usbutils
        traceroute
        fd ripgrep
        tree
        file pv
        ffmpeg mpv jq unzip zip
        sqlite-interactive
        btop sysstat
        hexyl
      ]
      ++ (with cfg.pkgs-unstable; [
        helix
      ])
      ++ (if cfg.wireless.wlan then [iw] else [])
      ++ (if cfg.xorg then [xclip] else [])
      ++ (if cfg.wayland then with cfg.pkgs-unstable; [
        fuzzel waybar grim slurp swappy hyprpicker fnott
        swaybg swaylock wl-clipboard
        waypipe
      ] else [])
      ++ (if cfg.graphical then [
        cfg.pkgs-unstable.alacritty speedcrunch
        # themes
        adapta-gtk-theme adapta-kde-theme
        breeze-icons volantes-cursors
        qalculate-gtk
      ] else []);

      sessionVariables = {
        TYPST_FONT_PATHS =
          if config.fonts.fontDir.enable
          then "/run/current-system/sw/share/X11/fonts"  # not sure if I should upstream this
          else "";
        QT_PLUGIN_PATH =
          if cfg.wayland
          then map (plugin: "${plugin}/lib") (with pkgs; [libsForQt5.qtwayland])
          else [];
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
        package = cfg.pkgs-unstable.sway;
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

        wrapperFeatures.gtk = true;
      };

      # shell
      zsh = {
        enable = true;
        autosuggestions.enable = true;
        promptInit = ''
          sign_color='6'
          if [[ $HOST == "elusive" ]]; then
            sign_color='2'
          fi
          PROMPT=" %D{%H %M} %F{$sign_color}%(!.#.=)%f "
          RPROMPT='%(?..%F{1}%?%f) %F{5}%~%f %F{4}@%M%f'
        '';
      };
    };

    xdg.portal = mkIf cfg.graphical {
      enable = true;
      extraPortals = with pkgs; [xdg-desktop-portal-gtk];
    };
    qt = {
      enable = true;
      platformTheme = "qt5ct";
    };

    security.sudo.extraConfig = concatStringsSep "\n" (
      mapAttrsToList (name: value: "Defaults " + (
        if (isBool value) then
          (optionalString (!value) "!") + name
        else if (isString value) then
          "${name}=\"${value}\""
        else
          "${name}=${toString value}"
      )) {
        # see sudoers(5)
        passwd_timeout = 0;
        timestamp_type = "global";

        passprompt = "${indent}${query} auth for %u${cha 8}";
        badpass_message = "${indent}${error} wrong password";
        authfail_message = " ${error} %d time(s) incorrect";
      }
    );

    virtualisation = {
      libvirtd.enable = true;
      kvmgt.enable = true;
    };

    nixpkgs.overlays = [
      (final: prev: {
        mpv = prev.mpv.override {
          scripts = with final.mpvScripts; [
            mpris
          ];
        };
      })
    ];
    nix.settings = {
      auto-optimise-store = true;
      experimental-features = ["nix-command" "flakes"];
    };
  };
}
