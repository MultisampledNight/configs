# GL HF!
It's dangerous out there, take this!

## Dependencies

```console
sudo pacman -S sccache alacritty neovim zsh waybar sway mako rustup
rustup install stable
cargo install evcxr
```

And be sure to install [vim-plug](https://github.com/junegunn/vim-plug) into NeoVim, too.

## Installation

In a sh-compatible shell:

```console
chsh -s /usr/bin/zsh
git clone https://github.com/MultisampledNight/configs
cp configs/* ${XDG_CONFIG_HOME:-~/.config}
cp configs/zsh/zshrc ~/.zshrc
cp configs/zsh/zprofile ~/.zprofile
```

And in NeoVim:

```
:PlugInstall
:TSInstall rust python vim lua html css julia c cpp latex
```

## What in the name of
These are most of my configuration files. Copy and paste out of them as much as you want, but mostly it really pays out if you read the manpages/helppages of the programs as well.

## About readability
These are partly about just having my configuration files backed up somewhere and partly about letting others use my configs if they want to. So I try to make it readable, but... on my own way.

## About updating
I doubt that I will update these very often. My config lives with me, and I change it as I need to.
