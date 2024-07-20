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
      blender

      layaway
    ] ++ (with cfg.pkgs-unstable; [
      # zathura for viewing, evince for live-reloading
      # since zathura flickers white when reloading, but evince does so only with the background color
      zathura
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
      policies = let
        librsIcon = "https://lib.rs/logo.svg";
        cratesIcon = "https://crates.io/favicon.ico";
        pypiIcon = "https://pypi.org/static/images/favicon.35549fe8.ico";

        pythonIcon = "https://docs.python.org/3/_static/py.svg";
        rustIcon = "https://doc.rust-lang.org/static.files/favicon-32x32-422f7d1d52889060.png";

        docsrsIcon = "https://docs.rs/-/static/favicon.ico";

        archIcon = "https://archlinux.org/static/favicon.51c13517c44c.png";
        nixIcon = "https://nixos.org/_astro/flake-blue.Bf2X2kC4_Z1yqDoT.svg";

        ytIcon = "https://www.youtube.com/s/desktop/a258f8cf/img/favicon_32x32.png";
        typstIcon = "https://typst.app/assets/favicon-32x32.png";
      in {
        DownloadDirectory = "\${home}/media/downloads";

        Cookies = {
          Behavior = "reject-foreign";
          BehaviorPrivateBrowsing = "reject";

          # surprisingly many websites just... don't work without third-party cookies
          # so yeah, here we allow them. unfortunately.
          Allow = [
            "https://www.zdf.de/"
            "https://docs.python.org/"
            "https://doc.rust-lang.org/"
            "https://www.openstreetmap.org/"
            "https://tile.openstreetmap.org/"
          ];
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

        NoDefaultBookmarks = true;
        Bookmarks = mapAttrsToList (name: url: {
          Title = name;
          URL = url;
          Favicon = if hasPrefix "Nix" name then nixIcon
            else if hasPrefix "Typst" name then typstIcon
            else "";
        }) {
          "NixOS manual" = "https://nixos.org/manual/nixos/stable/";
          "Nixpkgs manual" = "https://nixos.org/manual/nixpkgs/stable/";
          "Nix manual" = "https://nix.dev/manual/nix/rolling/";
          "Typst documentation" = "https://typst.app/docs";
          "oklch" = "https://oklch.com/";
        };

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
          Add = [
            {
              Name = "Lib.rs";
              Description = "Static frontend to the Rust crate index";
              Alias = "@rspkgs";
              URLTemplate = "https://lib.rs/search?q={searchTerms}";
              Method = "GET";
              IconURL = librsIcon;
            }
            {
              Name = "Rust crate registry";
              Alias = "@rspkgs-slow";
              URLTemplate = "https://crates.io/search?q={searchTerms}";
              Method = "GET";
              IconURL = cratesIcon;
            }
            {
              Name = "Python package index";
              Alias = "@pypkgs";
              URLTemplate = "https://pypi.org/search/?q={searchTerms}";
              Method = "GET";
              IconURL = pypiIcon;
            }
            {
              Name = "Arch Linux packages";
              Alias = "@archpkgs";
              URLTemplate = "https://archlinux.org/packages/?q={searchTerms}";
              Method = "GET";
              IconURL = archIcon;
            }
            {
              Name = "Nix packages";
              Alias = "@nixpkgs";
              URLTemplate = "https://search.nixos.org/packages?query={searchTerms}";
              Method = "GET";
              IconURL = nixIcon;
            }
            {
              Name = "Arch wiki";
              Alias = "@archdoc";
              URLTemplate = "https://wiki.archlinux.org/index.php?search={searchTerms}&title=Special%3ASearch";
              Method = "GET";
              IconURL = archIcon;
            }
            {
              Name = "Python stdlib documentation";
              Alias = "@pydoc";
              URLTemplate = "https://docs.python.org/3/search.html?q={searchTerms}";
              Method = "GET";
              IconURL = pythonIcon;
            }
            {
              Name = "Rust stdlib documentation";
              Alias = "@rsdoc";
              URLTemplate = "https://doc.rust-lang.org/std/index.html?search={searchTerms}";
              Method = "GET";
              IconURL = rustIcon;
            }
            {
              Name = "Rust crate documentation";
              Alias = "@rsext";
              URLTemplate = "https://docs.rs/releases/search?query={searchTerms}&sort=recent-downloads";
              Method = "GET";
              IconURL = docsrsIcon;
            }
            {
              Name = "NixOS options";
              Alias = "@nixopts";
              URLTemplate = "https://search.nixos.org/options?query={searchTerms}";
              Method = "GET";
              IconURL = nixIcon;
            }
            {
              Name = "NixOS wiki";
              Alias = "@nixdoc";
              URLTemplate = "https://nixos.wiki/index.php?search={searchTerms}&go=Go";
              Method = "GET";
              IconURL = nixIcon;
            }
            {
              Name = "Typst universe";
              Alias = "@typpkgs";
              URLTemplate = "https://typst.app/universe/search?q={searchTerms}";
              Method = "GET";
              IconURL = typstIcon;
            }
            {
              Name = "YouTube";
              Alias = "@youtube";
              URLTemplate = "https://www.youtube.com/results?search_query={searchTerms}";
              Method = "GET";
              IconURL = ytIcon;
            }
            {
              Name = "ProtonDB";
              Alias = "@protondb";
              URLTemplate = "https://www.protondb.com/search?q={searchTerms}";
              Method = "GET";
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

      preferences = concatMapAttrs (prefix: settings:
        mapAttrs' (key: value:
          nameValuePair
            (if prefix == ""
              then key
              else "${prefix}.${key}")
            value
        ) settings
      ) {
        "" = {
          "browser.translations.automaticallyPopup" = "locked";
          "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
        };
        "browser.search.suggest" = {
          "enabled" = false;
          "enabled.private" = false;
          "addons" = false;
          "bestmatch" = false;
          "bookmark" = true;
          "engines" = true;
          "history" = false;
          "openpage" = false;
          "topsites" = false;
          "weather" = false;
        };
        "browser.urlbar" = {
          "placeholderName" = "nyaaa~~ rawr!! mrrp";
          "sponsoredTopSites" = false;
        };
        "browser.urlbar.suggest" = {
          "addons" = false;
          "bestmatch" = false;
          "bookmark" = true;
          "calculator" = true;
          "searches" = false;
          "engines" = false;
          "history" = false;
          "openpage" = false;
          "topsites" = false;
          "weather" = false;
        };
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
