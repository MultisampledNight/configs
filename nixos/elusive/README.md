In here are a few configurations for QEMU VMs, intended for my development environment system. Not supposed to be included from the host configuration.

# Goals

- If anything fails, only that one project is affected, and other project's secrets and state stay untouched. This is why caches mustn't be shared, too.
- The VM must be user-spawnable.
- Interaction with the VM must be easy.

# How it works

On the top level of this repository, there's a folder `scripts` with `elusive-generate-base` and `elusive`. These two are a hot mess, and it should be noted that this is barely a reusable solution, but rather an applied one, fitting my needs.

`elusive-generate-base` requires no arguments and generates a **base** image based off `configuration.nix` and `format.nix` in _this_ folder, puts it into the Nix store and registers it as a Nix GC root. This base image is then used by the actual `elusive` script accepting one argument, the path of the project to use it under, which firstly creates an **overlay** over the **base** for the project in `~/zukunftslosigkeit/state/elusive/$project/overlay.qcow2`. Afterwards, it launches a QEMU VM with pretty exhaustive resources with the **overlay** as target.

Overlay and base works like a local git branch in comparison to upstream — if they both don't have any changes, the overlay (branch) is empty since the base (upstream) contains everything needed. Once they diverge, the overlay (branch) accumulates the differences. If desired, the overlay (branch) can be rebased ontop of the image (upstream) again, so differences are resolved and the overlay (branch) contains the minimum amount of changes again.

QEMU stores for an overlay where its base image is. Due to this, if `elusive-generate-base` notices that the new image would replace a previous image as Nix GC root, it'll automatically run through all overlays in `~/zukunftslosigkeit/state/elusive` and rebase them ontop of the new image. To make this easier, they reference the images _directly_ in the store rather than the Nix GC root symlink, which implies that they're not naively portable without rebasing/copying either.

# How to use

- Firstly, run `elusive-generate-base` once, which will probably take less than 10 minutes.
    - If you want to use `elusive-ssh` or `elusive-rsync`, run `ssh-keygen -f ~/.ssh/id_to_elusive -t ed25519` **beforehand**.
    - This base image contains all shells and development tools I need for development.
- Anytime you want a VM for a project, run `elusive <tag>`, where `<tag>` can be any string you want (that your filesystem can store).
    - Using the same tag again will give you the same VM again, with all state persisted (unless you clean it).
    - Using a new tag generates a new overlay.
    - The overlay only contains the difference to the base image. That is, if you just want to quickly try something in a clean environment, the overlay will only store the effects of your work, and nothing else.
- For interacting with the VM once it's launched, you can use:
    - The spawned window. You're automatically logged in as `multisn8`, and the `.zlogin` launches Sway without further interaction. In order to avoid conflicts with the host potentially also running Sway, `$mod` is bound to `Alt` (instead of the `Mod4`/"Super" which is the case on the host).
        - Shutdown can be performed using <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>2</kbd> in the spawned window, typing `system_powerdown` and <kbd>Enter</kbd>.
        - A bare Linux console is accessible over <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>3</kbd>.
        - Fullscreen mode can be escaped from using <kbd>Ctrl</kbd> + <kbd>Alt</kbd> + <kbd>F</kbd>.
    - `elusive-ssh` without any arguments, giving you an SSH session in your current terminal into the VM.
    - `elusive-rsync`, which is rsync, except that `localhost`/`127.0.0.1`/`elusive` will refer to the VM.
    - `elusive-clone`, which accepts 1 argument, and **clones** the given directory under the same path **into** the VM through `elusive-rsync`.
    - `elusive-reverse-clone`, which is `elusive-clone`, but the other way around. That is, it clones the given directory **out of** the VM.
    - `elusive-sshfs`, which is just like `elusive-rsync`, but with sshfs instead.
    - `elusive-mount`, which is just like `elusive-clone`, but with `elusive-sshfs` instead.
- Finally, if you wish to delete a VM's persistent state, you can do so by deleting the folder `~/zukunftslosigkeit/state/elusive/<tag>`, where `<tag>` refers to the VM tag you want to delete. If you want to do so for ***ALL*** VMs, `elusive-clean-state` is a shortcut for deleting the `elusive` folder. Do note that it **does not** ask for confirmation though.

# Caveats

- Currently, at any point of time, on one machine there can be at most 1 VM running.
    - This is due to the SSH port number of the VM being hardcoded for the moment. This is fixable and port numbers could be "allocated", with all `elusive-*` commands taking the tag as argument, but this is not the case for the time being.
- VMs cannot be updated directly. The only possibility to do so is by cleaning state and regenerating the base image.
    - Not sure how to solve this. `make-disk-image.nix` in nixpkgs always generates a new image, and doesn't allow modification of an existing one. And it is kind of inefficient to run the same `sudo nixos-rebuild switch --upgrade` commands in the VMs, with all of them accessing the net. Or they could access the host as a cacher... hm. Either way, that'd mean sudo is unlocked inside of the VM. Which is undesired (although technically safe, I believe).
- When using the proprietary Nvidia drivers, **not** using Wayland will cause a black screen on the spawned window of the VM. There's several possibilties:
    - Use Wayland. Yeah, it most likely works. No, it's not completely unsupported. Yeah, you'll get bugs. Software.
    - Use the SDL backend instead, by replacing `gtk` with `sdl` in the `elusive` script (and removing the `full-screen=on` argument). This might break your keyboard layout, for example, on Bone it makes layer 3 completely inaccessible.
    - Ignore the black output and work only over `elusive-ssh` or the like.

# Why not X instead?

where X is

- docker/podman/lxc/systemd-nspawn/nixos-container: Those are just containers, still sharing the kernel. I want an actual different machine to hack on, which is what the VM does.
- bubblewrap/firejail: Same thing as with containers.
- virtiofs(d) instead of sshfs: Somehow doesn't play nicely with mmap, and as such no Rust project was buildable over it.
- Guest → Host communication: Difficult to limit. If you want to offer a few directories over ssh, you'd need a different user on the host for it. And as such the VM has the same rights as the user, and runs on the same kernel again.
- Xorg: no. It causes more issues at this point than it'd be worth to keep it. The X server installed into elusive is also semi-functional at the moment, it does display, it is possible to launch applications using the serial console/SSH, but it accepts no input.

# Credits

- https://people.kernel.org/brauner/runtimes-and-the-curse-of-the-privileged-container which made me consider QEMU instead
- https://wiki.archlinux.org/title/QEMU
- https://github.com/nix-community/nixos-generators for generating the base image

