# configs but it's actually a [NixOS](https://nixos.org) configuration

Most configs in here can be used without NixOS though.

## Installation

**Note:** This will install **all** configs without asking.

If you already have a running NixOS installation, great! A lovely script can take care of setting up symlinks like `/etc/nixos` to this repo:

```console
git clone https://github.com/MultisampledNight/configs
cd configs
sudo ./distribute_symlinks.py
sudo nixos-rebuild switch
```

If you don't have a running NixOS installation, you can set up a minimal one with only bootloader, and then run the same inside of its chroot with `nixos-enter`.
