# Shells

In here are `default.nix`es intended for `nix-shell`, usually one for each language or common environment. There's a couple things to note though.

## "Definite" access

This directory is symlinked from `~/zukunftslosigkeit/shells`.

## `~/.zshrc`

It performs a few QoL things worth noting.

- `NIX_PATH` is set to additionally include this directory (actually the symlink).
    - This makes it possible to launch any shell here simply by putting the folder name in angle brackets (and escaping them properly for zsh), as in `nix-shell '<typst>'` for a [typst] shell.
    - Of course this also implies that shells shouldn't be named anything funny, like `nixpkgs` or `nixos`. They'll be shadowed by the earlier `NIX_PATH` entries anyway.
- It shadows the `nix-shell` command to
    1. Make it launch zsh instead of bash.
    2. Set the environment variable `SHELL_NAME` appropiately. It's not anything magical, or used by anything else, it's just for the command line prompt to accurately display what shells one is actually in.
- It also additionally provides a `shell` command, which allows quick nesting of multiple shells and doesn't require all those tedious angle brackets and quotes.
    - For example, a quick shell with [Rust], [Python] and [typst] is as easy as `shell rust python typst`.


## Interaction with `direnv`

The shells are not supposed to be leaked to the outside world, but can be useful for local development. Often it's already clear that one project will _always_ require that one shell to be loaded in order to meaningfully develop it. To facilitate this, `direnv` is loaded in `~/.zshrc`, but only on [elusive].

An example `.envrc` for a typical [Rust] project **for local development** might be this one:

```sh
export SHELL_NAME="${SHELL_NAME:+$SHELL_NAME/}rust"
use nix '<rust>'
```

Since `direnv` is loaded only on [elusive], it's hasslefree to navigate in these directories on the host without triggering 3000 warnings and error messages.

## Interaction with [elusive]

All shells are evaluated once and put into the Nix store on the [elusive] base image, to make sure their dependencies don't have to be downloaded on actual use.

[Rust]: https://www.rust-lang.org/
[Python]: https://www.python.org/
[typst]: https://typst.app/
[elusive]: ../../nixos/elusive/README.md
