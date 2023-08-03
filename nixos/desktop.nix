{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;
in {
  imports =
    [
      ./development.nix
    ];

  boot.supportedFilesystems = ["ntfs"];

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

  sound.enable = true;
  security.rtkit.enable = true;
  xdg.portal.enable = lib.mkForce false;
  qt = {
    enable = true;
    platformTheme = "qt5ct";
  };

  networking = {
    dhcpcd.wait = "background"; # saves like 5 seconds of startup time

    hosts = {
      "127.0.0.1" = ["elusive"];
    };
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
      helvum
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
