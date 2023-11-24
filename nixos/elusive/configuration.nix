{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;

  configs = ./../..;
in {
  imports = 
    [
      ./../generalized.nix
      ./../development.nix
    ];

  generalized = {
    hostName = "elusive";
    ssh = true;
    wayland = true;
    xorg = true;
    hidpi = false;
    videoDriver = "virtio";
    audio = true;
    forMulti = false;
  };

  boot = {
    kernelParams = ["kernel.perf_event_paranoid=0"];
    loader = {
      systemd-boot.enable = mkForce false;
      grub.enable = mkForce true;
    };
  };

  hardware.opengl.extraPackages = with pkgs; [swiftshader];

  users = {
    defaultUserShell = pkgs.zsh;
    mutableUsers = false;

    # this is an externally managed VM, no I don't want to have it magically modify itself
    # so make sure the root user is NOT loginable
    allowNoPasswordLogin = true;
    users = {
      root = {
        password = null;
        hashedPassword = null;
        passwordFile = null;
      };

      multisn8 = {
        isNormalUser = true;
        password = "";
        # generate a new one using
        # ssh-keygen -f ~/.ssh/id_to_elusive -t ed25519
        openssh.authorizedKeys.keyFiles = [
          ~/.ssh/id_to_elusive.pub
        ];
      };
    };
  };

  environment.extraInit = ''
    export LD_LIBRARY_PATH="${makeLibraryPath (with pkgs; [gcc-unwrapped.lib])}:$LD_LIBRARY_PATH"
  '';

  services = {
    getty.autologinUser = "multisn8";
    xserver.desktopManager.plasma5.enable = true;
  };

  system.stateVersion = "23.05";
}
