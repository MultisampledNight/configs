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

  hardware = {
    sane.enable = true;
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

    libinput.enable = true;
    xserver = {
      enable = cfg.xorg;

      xkb = {
        layout = if cfg.forTheGeneralPublic then "de"
          else if cfg.layout == "bone" then "de"
          else cfg.layout;
        variant = if cfg.layout == "bone" then "bone" else "";
      };

      videoDrivers = [cfg.videoDriver];

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
      tor-browser-bundle-bin thunderbird
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
      pinentryPackage = pkgs.pinentry-curses;
    };

    ssh.askPassword = "${pkgs.libsForQt5.ksshaskpass}/bin/ksshaskpass";

    firefox = {
      enable = true;
      package = pkgs.firefox-esr;
      # https://mozilla.github.io/policy-templates/
      policies = {
        DownloadDirectory = "\${home}/media/downloads";

        Cookies = {
          Behavior = "reject-foreign";
          BehaviorPrivateBrowsing = "reject";
        };
        SanitizeOnShutdown = {
          Cache = true;
          Cookies = true;
          Downloads = false;
          FormData = true;
          History = true;
          Sessions = true;
          SiteSettings = true;
          OfflineApps = true;
          Locked = false;
        };
        EnableTrackingProtection = {
          Value = true;
          Cryptomining = true;
          Fingerprinting = true;
          EmailTracking = true;
        };
        Permissions = {
          Camera.BlockNewRequests = true;
          Microphone.BlockNewRequests = true;
          Location.BlockNewRequests = true;
          Notifications.BlockNewRequests = true;
          Autoplay.Default = "block-audio-video";
        };

        DNSOverHTTPS = {
          Enabled = true;
          Fallback = true;
        };
        NetworkPrediction = false;
        HttpsOnlyMode = "enabled";
        PostQuantumKeyAgreementEnabled = true;

        NoDefaultBookmarks = true;
        ManagedBookmarks = [
          {
            name = "NixOS manual";
            url = "https://nixos.org/manual/nixos/stable/";
          }
          {
            name = "Nixpkgs manual";
            url = "https://nixos.org/manual/nixpkgs/stable/";
          }
          {
            name = "Nix manual";
            url = "https://nix.dev/manual/nix/rolling/";
          }
          {
            name = "Typst documentation";
            url = "https://typst.app/docs";
          }
        ];

        SearchSuggestEnabled = false;
        DontCheckDefaultBrowser = true;
        PromptForDownloadLocation = false;

        AutofillAddressEnabled = false;
        AutofillCreditCardEnabled = false;
        OfferToSaveLogins = false;
        PasswordManagerEnabled = false;
        DisableFormHistory = true;

        DisableFirefoxAccounts = true;
        DisableFirefoxScreenshots = true;
        DisableFirefoxStudies = true;
        DisablePocket = true;
        DisableProfileImport = true;
        DisableTelemetry = true;

        DisableSetDesktopBackground = true;

        ShowHomeButton = false;
        DisplayBookmarksToolbar = "never";
        DisplayMenuBar = "never";

        SearchBar = "unified";
        SearchEngines = {
          PreventInstalls = true;

          Default = "DuckDuckGo";
          Add = let
            archLogo = "https://archlinux.org/static/favicon.51c13517c44c.png";
            nixLogo = "https://nixos.org/_astro/flake-blue.Bf2X2kC4_Z1yqDoT.svg";
            ytLogo = "https://www.youtube.com/s/desktop/a258f8cf/img/favicon_32x32.png";
          in [
            {
              Name = "Arch Linux packages";
              Alias = "@archpkgs";
              URLTemplate = "https://archlinux.org/packages/?q={searchTerms}";
              Method = "GET";
              IconURL = archLogo;
            }
            {
              Name = "Nix packages";
              Alias = "@nixpkgs";
              URLTemplate = "https://search.nixos.org/packages?query={searchTerms}";
              Method = "GET";
              IconURL = nixLogo;
            }
            {
              Name = "Arch wiki";
              Alias = "@archdoc";
              URLTemplate = "https://wiki.archlinux.org/index.php?search={searchTerms}&title=Special%3ASearch";
              Method = "GET";
              IconURL = archLogo;
            }
            {
              Name = "NixOS options";
              Alias = "@nixopts";
              URLTemplate = "https://search.nixos.org/options?query={searchTerms}";
              Method = "GET";
              IconURL = nixLogo;
            }
            {
              Name = "NixOS wiki";
              Alias = "@nixdoc";
              URLTemplate = "https://nixos.wiki/index.php?search={searchTerms}&go=Go";
              Method = "GET";
              IconURL = nixLogo;
            }
            {
              Name = "YouTube";
              Alias = "@youtube";
              URLTemplate = "https://www.youtube.com/results?search_query={searchTerms}";
              Method = "GET";
              IconURL = ytLogo;
            }
          ];

          Remove = [
            "Google"
            "Bing"
          ];
        };

        OverridePostUpdatePage = "";
        FirefoxHome = {
          Search = true;
          TopSites = false;
          SponsoredTopSites = false;
          Highlights = false;
          Pocket = false;
          SponsoredPocket = false;
          Snippets = false;
          Locked = true;
        };
        UserMessaging = {
          ExtensionsRecommendations = false;
          FeatureRecommendations = false;
          UrlbarInterventions = false;
          SkipOnboarding = true;
          MoreFromMozilla = false;
          Locked = true;
        };

        ExtensionSettings = let
          moz = short: "https://addons.mozilla.org/firefox/downloads/latest/${short}/latest.xpi";
        in {
          "*" = {
            allowed_types = ["extension" "theme"];
          };
          "addon@darkreader.org" = {
            install_url = moz "darkreader";
            installation_mode = "force_installed";
          };
          "uBlock0@raymondhill.net" = {
            install_url = moz "ublock-origin";
            installation_mode = "force_installed";
          };
        };
      };

      preferences = {
        "browser.translations.automaticallyPopup" = "locked";
        "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
      };
    };

    steam = mkIf cfg.gaming {
      enable = true;
      remotePlay.openFirewall = true;
    };
  };

  nixpkgs = {
    config.allowUnfree = true;

    overlays = [];
  };

  system.copySystemConfiguration = true;
}
