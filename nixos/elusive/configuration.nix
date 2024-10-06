{ name }:
{ config, lib, pkgs, modulesPath, ... }:

let
  efiArch = pkgs.stdenv.hostPlatform.efiArch;

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
        contents = {
          "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source =
            "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
        };
        repartConfig = {
          Type = "esp";
          Label = "P_BOOT";
          Format = "vfat";
          SizeMinBytes = "256M";
        };
      };
      root = {
        storePaths = [config.system.build.toplevel] ++ shells;
        repartConfig = {
          Type = "root";
          Label = "p_${name}";
          Format = "ext4";
          SizeMinBytes = "75G";
        };
      };
    };
  };

  fileSystems."/".device = "/dev/disk/by-label/p_${name}";
  fileSystems."/boot".device = "/dev/disk/by-label/P_BOOT";

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
