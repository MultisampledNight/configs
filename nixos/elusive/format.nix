# taken and modified from https://github.com/nix-community/nixos-generators, which is licensed as under
# 
# MIT License
# 
# Copyright (c) 2019 lassulus and the nixos-generators contributors
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

{ config, lib, pkgs, modulesPath, ... }:

let
  configs = ./../..;
  symlinkSkeleton = pkgs.runCommand "elusive-symlink-skeleton" {} ''
    ${pkgs.python3}/bin/python \
        ${configs}/distribute_symlinks.py \
        --root "$out" --user multisn8 \
        --actually-install --exclude-nixos --no-backup &>/dev/null
  '';
  shellDir = ../../nix/shells;
  shells =
    lib.mapAttrsToList
      (name: _: pkgs.callPackage (shellDir + "/${name}/default.nix") {})
      (lib.filterAttrs (_: type: type == "directory") (builtins.readDir shellDir));
in {
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
  };

  boot = {
    growPartition = true;
    kernelParams = ["console=ttyS0"];
    loader.grub.device = "/dev/vda";
    loader.timeout = 0;
    initrd.availableKernelModules = ["uas"];
  };

  system.build.raw = import "${toString modulesPath}/../lib/make-disk-image.nix" {
    inherit lib config pkgs;
    diskSize = "auto";
    format = "raw";

    name = "elusive-base-image";
    partitionTableType = "legacy+gpt";
    memSize = 8 * 1024; # in MiB

    # install the configs
    # unfortunately there's no nice way to run commands _inside_ of the VM, so instead we prepare the home structure out-of-VM and then just copy it in
    contents = [
      {
        source = "${symlinkSkeleton}/home/multisn8";
        target = "/home/multisn8";
        user = "multisn8";
        group = "users";
      }
      {
        source = "${configs}/nixos/elusive/mounts";
        target = "/etc/elusive-mounts";
        user = "multisn8";
        group = "users";
      }
    ];
    additionalPaths = shells;
  };

  formatAttr = "raw";
  filename = "*.img";
}
