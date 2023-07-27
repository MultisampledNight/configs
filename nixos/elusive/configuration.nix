{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.generalized;

  configs = ./../..;
  resizeSerialConsole = pkgs.writeShellScriptBin "resize" ''
    if [ -e /dev/tty ]; then
      old=$(stty -g)
      stty raw -echo min 0 time 5
      printf '\033[18t' > /dev/tty
      IFS=';t' read -r _ rows cols _ < /dev/tty
      stty "$old"
      stty cols "$cols" rows "$rows"
    fi
  ''; # https://unix.stackexchange.com/questions/16578/resizable-serial-console-window
in {
  imports = 
    [
      ./../generalized.nix
      ./../development.nix
    ];

  generalized = {
    hostName = "elusive";
    ssh = true;
    # note that no display protocol is specified
    graphical = true;
    forMulti = false;
  };

  boot.loader = {
    systemd-boot.enable = mkForce false;
    grub.enable = mkForce true;
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
        extraGroups = ["power"];
      };
    };
  };

  environment.loginShellInit = "${resizeSerialConsole}/bin/resize";

  services.openssh.settings = mkForce {
    PasswordAuthentication = true;
    KbdInteractiveAuthentication = true;
  };
  systemd.services.elusive-mounts = {
    description = "Mount all folders shared by the host";
    wantedBy = ["multi-user.target"];

    script = builtins.readFile (
      pkgs.runCommand "elusive-mounts" {
        buildInputs = with pkgs; [python3];
      } ''
        python3 ${configs}/scripts/elusive-instantiate-mounts \
          --mounts ${configs}/nixos/elusive/mounts \
          guest-mount > $out
      ''
    );
  };

  system.stateVersion = "23.05";
}
