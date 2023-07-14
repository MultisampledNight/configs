In here are a few configurations for QEMU VMs, intended for my development environment system. Not supposed to be included from the host configuration.

# How it works

On the top level of this repository, there's a folder `scripts` with `elusive-generate-base` and `elusive`. These two are a hot mess, and it should be noted that this is barely a reusable solution, but rather an applied one, fitting my needs.

`elusive-generate-base` requires no arguments and generates a **base** image based off `configuration.nix` and `format.nix` in _this_ folder, puts it into the Nix store and registers it as a Nix GC root. This base image is then used by the actual `elusive` script accepting one argument, the path of the project to use it under, which firstly creates an **overlay** over the **base** for the project in `~/zukunftslosigkeit/state/elusive/$project/overlay.qcow2`. Afterwards, it launches a QEMU VM with pretty exhaustive resources with the **overlay** as target.

Overlay and base works like a local git branch in comparison to upstream — if they both don't have any changes, the overlay (branch) is empty since the base (upstream) contains everything needed. Once they diverge, the overlay (branch) accumulates the differences. If desired, the overlay (branch) can be rebased ontop of the image (upstream) again, so differences are resolved and the overlay (branch) contains the minimum amount of changes again.

QEMU stores for an overlay where its base image is. Due to this, if `elusive-generate-base` notices that the new image would replace a previous image as Nix GC root, it'll automatically run through all overlays in `~/zukunftslosigkeit/state/elusive` and rebase them ontop of the new image. To make this easier, they reference the images _directly_ in the store rather than the Nix GC root symlink, which implies that they're not naively portable without rebasing/copying either.
