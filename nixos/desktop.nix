{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;
in {
  imports =
    [
      ./development.nix
    ];

  hardware = {
    pulseaudio.enable = false; # handled by pipewire-pulse instead
    opengl = {
      enable = true;
      extraPackages = if cfg.videoDriver == "intel"
        then with pkgs; [mesa.drivers intel-media-driver intel-compute-runtime]
        # TODO: sometime in future, I suppose also nvidia's ICD belongs here?
        else [];
    };

    nvidia = if cfg.videoDriver == "nvidia"
      then {
        modesetting.enable = true;
        open = false;
      }
      else {};
  };

  sound.enable = true;
  security.rtkit.enable = true;
  networking.dhcpcd.wait = "background"; # saves like 5 seconds of startup time
  xdg.portal.enable = lib.mkForce false;
  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };

  users.users =
    mkIf cfg.gaming {
      nichthemeron = {
        isNormalUser = true;
        extraGroups = if cfg.graphical then ["input"] else [];
        shell = pkgs.zsh;
      };
    };

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
    systemPackages = with pkgs;
    [
      # system debugging tools
      clinfo vulkan-tools pciutils

      # tools
      pulseaudio-ctl playerctl
      vde2 linuxKernel.packages.linux_zen.usbip lm_sensors
    ]
    ++ (if cfg.graphical then [
      # normal applications
      configuredFirefox tor-browser-bundle-bin thunderbird
      okular zathura
      blender gimp inkscape musescore
      obsidian libreoffice-fresh
      pavucontrol carla
      mate.eom
      dunst virt-manager qemu_kvm
      qt5ct

      # themes
      adapta-gtk-theme adapta-kde-theme adapta-backgrounds
      breeze-icons volantes-cursors
    ] else [])
    ++ (if cfg.xorg then [
      xorg.xauth rofi flameshot
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
    };
  };

  programs = {
    adb.enable = true;
    dconf.enable = true;
    firejail.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
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
