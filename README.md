# configs but it's actually a [NixOS](https://nixos.org) configuration

Most configs in here can be used without NixOS though.

## Installation

**Note:** This will install **all** configs without asking. Did I mention that the script is hardcoded to `/home/multisn8` as the home path? Yeah, this tells a lot about when it should be used by you --- never, at least not under extensive change.

If you already have a running NixOS installation, great! A lovely script can take care of setting up symlinks like `/etc/nixos` to this repo:

```console
git clone https://github.com/MultisampledNight/configs
cd configs
sudo ./distribute_symlinks.py
nixos-generate-config
```

However, you still need to create a suitable `configuration.nix` in (the now symlinked) `/etc/nixos`! Through inclusion of `generalized.nix` and the appropiate model (like `desktop.nix` or `portable.nix`) this should be pretty easy though. `generalized.nix` contains descriptions for all its exposed values, you don't really need to setup anything else apart from maybe the `system.stateVersion`.

Afterwards, run `sudo nixos-rebuild switch`, and you're good to go!

If you don't have a running NixOS installation, you can set up a minimal one with only the bootloader, and then run the same inside of its chroot with `nixos-enter`.
