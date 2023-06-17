{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;
  neovideSmooth = pkgs.callPackage ./neovide/default.nix {};
in
{
  boot = {
    kernelPackages = mkDefault (
      if cfg.profileGuided
      then pkgs.linuxZenFast
      else pkgs.linuxKernel.packages.linux_zen
    );

    loader.grub = {
      font = "${pkgs.ibm-plex}/share/fonts/opentype/IBMPlexMono-Medium.otf";
      fontSize = 25;
    };
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

  documentation = {
    enable = true;
    man.generateCaches = true;
  };

  hardware = {
    pulseaudio.enable = false; # handled by pipewire-pulse instead
    opengl = {
      enable = true;
      extraPackages = if cfg.videoDriver == "intel"
        then with pkgs; [intel-media-driver intel-compute-runtime]
        else [];
    };

    nvidia = if cfg.videoDriver == "nvidia"
      then {
        modesetting.enable = true;
        open = true;
      }
      else {};
  };

  sound.enable = true;
  security.rtkit.enable = true;
  networking.dhcpcd.wait = "background"; # saves like 5 seconds of startup time
  xdg.portal.enable = lib.mkForce false;

  users.users =
    if cfg.gaming then {
      nichthemeron = {
        isNormalUser = true;
        extraGroups = if cfg.wayland || cfg.xorg then ["input"] else [];
        shell = pkgs.zsh;
      };
    } else {};

  services = {
    # audio server
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      wireplumber.enable = true;
    };

    udisks2.enable = true;
    printing.enable = true;

    # hide the mouse cursor when not moved
    unclutter-xfixes = {
      enable = cfg.xorg;
      timeout = 8;
    };

    xserver = {
      enable = cfg.xorg;

      layout = if cfg.forTheGeneralPublic then "de"
        else if cfg.layout == "bone" then "de"
        else cfg.layout;
      xkbVariant = if cfg.layout == "bone" then "bone" else "";
      libinput.enable = true;

      videoDrivers = [cfg.videoDriver];

      displayManager = {
        defaultSession = if cfg.forTheGeneralPublic then "gnome"
          else if cfg.wayland then "sway"
          else "none+i3";
        gdm.enable = cfg.xorg;
      };

      desktopManager = {
        plasma5.enable = cfg.forTheGeneralPublic;
        gnome.enable = cfg.forTheGeneralPublic;
        wallpaper = {
          mode = "fill";
          combineScreens = false;
        };
      };
      windowManager = {
        i3 = {
          enable = true;
        };
      };
    };
  };

  environment = {
    systemPackages = with pkgs; [
      # system debugging tools
      clinfo vulkan-tools pciutils

      # tools
      file pv btop ffmpeg jq
      alacritty xclip delta
      inotify-tools
      pulseaudio-ctl playerctl
      sshfs vde2 linuxKernel.packages.linux_zen.usbip lm_sensors
      geoipWithDatabase

      # themes
      adapta-gtk-theme adapta-kde-theme adapta-backgrounds
      breeze-icons volantes-cursors

      # languages (for Rust it's probably better to directly use a shell.nix instead)
      python3 black
      llvmPackages_latest.llvm llvmPackages_latest.bintools llvmPackages_latest.lld
      clang sccache texlive.combined.scheme-full texlab

      # dev applications
      ghidra
      neovideSmooth sqlitebrowser
      direnv

      # gamedev
      godot_4

      # normal applications
      configuredFirefox thunderbird okular blender gimp inkscape obsidian libreoffice-fresh zathura
      pavucontrol carla
      mpv mate.eom
      dunst
    ]
    ++ (if cfg.xorg then [
      xorg.xauth rofi flameshot
    ] else [])
    ++ (if cfg.videoDriver == "nvidia" then [
      cudatoolkit
    ] else [])
    ++ (if cfg.forTheGeneralPublic then [
      jetbrains.pycharm-community
      R nodejs openjdk
    ] else [])
    ++ (if cfg.videos then [
      # OBS Studio and its plugins
      (wrapOBS {
        plugins = with obs-studio-plugins; [
          obs-vkcapture
          obs-pipewire-audio-capture
          input-overlay 
        ];
      })
      libsForQt5.kdenlive
    ] else []);

    sessionVariables = {
      BROWSER = "firefox";
      NEOVIDE_MULTIGRID = "true";
      WLR_NO_HARDWARE_CURSORS = "1";
      TYPST_FONT_PATHS =
        if config.fonts.fontDir.enable
        then "/run/current-system/sw/share/X11/fonts"  # not sure if I should upstream this
        else "";
    }
    // (if cfg.videoDriver == "nvidia" then {
      # both required for blender
      CUDA_PATH = "${pkgs.cudatoolkit}";
      CYCLES_CUDA_EXTRA_CFLAGS = "-I${pkgs.cudatoolkit}/targets/x86_64-linux/include";
    } else {})
    // (if cfg.wayland then {
      NIXOS_OZONE_WL = "1";
    } else {});

    extraInit = (if cfg.videoDriver == "nvidia" && cfg.xorg then ''
      export LD_LIBRARY_PATH="${pkgs.linuxPackages.nvidia_x11}/lib"
    '' else "")
    + (if cfg.xorg then ''
      # is X even running yet?
      if [[ -n $DISPLAY ]]; then
        # key repeat delay + rate
        xset r rate 260 30
        # turn off the bell sound
        xset b off
      fi
    '' else "");
  };

  programs = {
    adb.enable = true;
    firejail.enable = true;

    git.lfs = {
      enable = true;
    };

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    neovim = {
      defaultEditor = !cfg.forTheGeneralPublic;
      withNodeJs = true;
      # temporary until https://github.com/NixOS/nixpkgs/pull/237357 hits unstable
      withPython3 = false;

      configure = {
        customRC = ''
          silent! source ${pkgs.vimPlugins.vim-plug}/plug.vim
          silent! source ~/.config/nvim/init.vim
        '';
      };
    };

    ssh = {
      askPassword = "${pkgs.gnome.seahorse}/libexec/seahorse/ssh-askpass";
    };

    steam = mkIf cfg.gaming {
      enable = true;
      remotePlay.openFirewall = true;
    };

    sway = {
      enable = cfg.wayland;
      wrapperFeatures.gtk = true;
      extraPackages = with pkgs; [
        fuzzel waybar mako grim slurp swappy hyprpicker gammastep
        swaybg swaylock wl-clipboard
      ];
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
    };

    xwayland.enable = false;  # enabled by default by sway, but I don't need it
  };

  fonts = {
    fonts = with pkgs; [
      hack-font
      roboto roboto-mono
      ibm-plex
      source-code-pro

      cantarell-fonts
      inter
      overpass
      ttf_bitstream_vera
      ubuntu_font_family
    ];

    fontDir.enable = true;
    # this adds a few commonly expected fonts like liberation...
    enableDefaultFonts = true;

    fontconfig = {
      hinting.style = "hintfull";

      # ...while this one sets the actually in-place default fonts
      defaultFonts = {
        serif = ["IBM Plex Serif"];
        sansSerif = ["IBM Plex Sans"];
        monospace = ["IBM Plex Mono"];
      };
    };
  };

  nixpkgs = {
    config.allowUnfree = true;

    overlays = [
      (final: prev: {
        configuredFirefox = pkgs.wrapFirefox pkgs.firefox-unwrapped {
          extraPolicies = {
            DisableFirefoxStudies = true;
            DisablePocket = true;
            DisableTelemetry = true;
            DisableFirefoxAccounts = true;
            DisplayBookmarksToolbar = "never";
            FirefoxHome = {
              Pocket = false;
              Snippets = false;
            };
            NoDefaultBookmarks = true;
            OfferToSaveLogins = false;
            SearchSuggestEnabled = false;
            UserMessaging = {
              ExtensionsRecommendations = false;
              SkipOnboarding = true;
            };
          };
        };
      })
      (final: prev: if (cfg.videoDriver == "nvidia") then {
        blender = prev.blender.override {
          cudaSupport = true;
        };
      } else {})
      (final: prev: if (cfg.videoDriver == "nvidia" && cfg.wayland) then {
        # blatantly taken from https://wiki.hyprland.org/hyprland-wiki/pages/Nvidia/
        wlroots = prev.wlroots.overrideAttrs (finalAttrs: prevAttrs: {
          postPatch = (prev.postPatch or "") + ''
            substituteInPlace render/gles2/renderer.c --replace "glFlush();" "glFinish();"
          '';
        });
      } else {})
      (final: prev: if cfg.profileGuided then {
        godot_4 = prev.godot_4.override {
          stdenv = pkgs.fastStdenv;
        };

        linuxZenFast = pkgs.linuxPackagesFor (pkgs.linuxKernel.kernels.linux_zen.override {
          stdenv = pkgs.fastStdenv;
        });
      } else {})
    ];
  };

  system.copySystemConfiguration = true;
}
