{ config, pkgs, lib, ... }:

{
  imports = 
    [
      ./../generalized.nix
    ];

    isoImage.squashfsCompression = "zstd -Xcompression-level 6";

  generalized = {
    hostName = "elusive";
    ssh = true;
    forMulti = false;
  };


  boot = {
    loader.timeout = lib.mkForce 1;
    # nice for debugging, but ssh offers more casual terminal features
    #kernelParams = ["console=ttyS0"];
  };
  
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
      };
    };
  };

  environment.systemPackages = [
  ];

  security.polkit.enable = true;

  services.openssh.settings = lib.mkForce {
    PasswordAuthentication = true;
    KbdInteractiveAuthentication = true;
  };

  system.stateVersion = "23.05";
}
