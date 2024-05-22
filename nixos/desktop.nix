{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;
  layaway = cfg.pkgs-unstable.callPackage ./packages/layaway/default.nix {};
in {
  imports =
    [
      ./development.nix
    ];

  boot.supportedFilesystems = ["ntfs"];

  sound.enable = true;
  security.rtkit.enable = true;

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
    printing = {
      enable = true;
      drivers = with pkgs; [brlaser];
    };
    joycond.enable = true;

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
        gdm = {
          enable = cfg.xorg;
          autoSuspend = false;
        };
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
      vde2 lm_sensors
    ]
    ++ (if cfg.graphical then [
      # normal applications
      configuredFirefox tor-browser-bundle-bin thunderbird
      keepassxc
      gimp inkscape scribus
      libreoffice-fresh
      pavucontrol carla
      mate.eom
      dunst virt-manager qemu_kvm
      qt5ct
      helvum
      libsForQt5.kruler
      gucharmap
      element-desktop signal-desktop
      evince
      gnome.gnome-boxes

      layaway
    ] ++ (with cfg.pkgs-unstable; [
      # zathura for viewing, evince for live-reloading
      # since zathura flickers white when reloading, but evince does so only with the background color
      zathura
      blender
      obsidian 
      scrcpy
    ]) else [])
    ++ (if cfg.xorg then [
      xorg.xauth rofi flameshot
    ] else [])
    ++ (if cfg.multimedia then [
      # video
      # OBS Studio and its plugins
      (wrapOBS {
        plugins = with obs-studio-plugins; [
          obs-vkcapture
          obs-pipewire-audio-capture
          input-overlay 
        ];
      })
      libsForQt5.kdenlive

      # audio
      audacity lmms musescore vcv-rack polyphone
      easyeffects
    ] else []);

    sessionVariables = {
      BROWSER = "firefox";
    };
  };

  programs = {
    adb.enable = true;
    dconf.enable = true;
    firejail.enable = true;
    nix-ld.enable = true;

    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryFlavor = "curses";
    };

    ssh.askPassword = "${pkgs.libsForQt5.ksshaskpass}/bin/ksshaskpass";

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
    ];
  };

  system.copySystemConfiguration = true;
}
