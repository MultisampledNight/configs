{ name }:
{ config, lib, pkgs, modulesPath, ... }:

with lib;
let
  efiArch = pkgs.stdenv.hostPlatform.efiArch;
  system = config.system;

  shells = map
    (shell: pkgs.callPackage ../../nix/shells/${shell}/default.nix {})
  [
    "elixir"
    "julia"
    "python"
    "rust"
    "sdl"
    "typst"
  ];

  # set up common things and symlinks for my workflow when actually working
  rootTemplate = pkgs.runCommand
    "root-template"
    {
      configRepo = ../..;
      buildInputs = with pkgs; [ python3 ];
    }
    ''
      mkdir $out

      # despite its name (TODO: change that sometime) it can also take care of copying configs, shells, the works
      python \
        $configRepo/distribute_symlinks.py \
        --exclude-nixos --no-backup --actually-install \
        --root $out --user multisn8
    '';
in {
  imports = [
    ../generalized.nix
    ../development.nix
    "${modulesPath}/image/repart.nix"
  ];

  image.repart = {
    inherit name;
    seed = "d2c6527b-d43b-49cd-b724-d4f1fdd771ec";

    # for the repartConfig key, see:
    # https://www.freedesktop.org/software/systemd/man/latest/repart.d.html
    partitions = {
      boot = {
        contents = let
          loader = system.boot.loader;
        in {
          "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source =
            "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
          "/EFI/Linux/${loader.ukiFile}".source =
            "${system.build.uki}/${loader.ukiFile}";
          "/loader/loader.conf".source = pkgs.writeText "systemd-boot-config" ''
            editor false
            auto-firmware false
            timeout 0
          '';
        };
        repartConfig = {
          Type = "esp";
          Label = "BOOT";
          UUID = "47b77fd0-1cb6-42e0-8228-44611f0617b6";

          Format = "vfat";
          SizeMinBytes = "256M";
        };
      };
      root = {
        contents."/".source = rootTemplate;
        storePaths = [system.build.toplevel] ++ shells;
        # TODO: get rid of elusive-ssh and elusive-rsync and do it all via ssh config
        repartConfig = {
          Type = "root";
          Label = "ROOT";
          UUID = "276d46b6-2405-4c27-a28c-2fbefc6a97cd";

          Format = "ext4";
          SizeMinBytes = "75G";
        };
      };
    };
  };

  fileSystems = mapAttrs' (name: target:
    nameValuePair target (let
      cfg = config.image.repart.partitions.${name}.repartConfig;
    in {
      device = "/dev/disk/by-label/${cfg.Label}";
      fsType = cfg.Format;
      noCheck = true;
    })
  ) {
    root = "/";
    boot = "/boot";
  };

  boot = {
    kernelParams = ["console=ttyS0"];
    uki = { inherit name; };
  };

  generalized = {
    hostName = name;
    baremetal = false;
    ssh = true;
    wayland = true;
  };

  users = {
    mutableUsers = false;
    users.multisn8.openssh.authorizedKeys.keyFiles = [
      ~/.ssh/id_to_elusive.pub
    ];
  };
  services.getty.autologinUser = "multisn8";

  services.journald.extraConfig = ''
    SystemMaxUse=10M
  '';

  system.stateVersion = "24.05";
}
