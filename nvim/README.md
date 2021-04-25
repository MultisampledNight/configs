# NeoVims configuration
I use both normal NeoVim as well as NeoVim Nightly. I adjusted my init.vim to work with both.

**IMPORTANT NOTE:** If you plan to use both normal and nightly NeoVim as well, install the Plugins first with NeoVim Nightly. Don't execute `:PlugClean` in the normal NeoVim.

## Images

![Image of my NeoVim setup](https://user-images.githubusercontent.com/80128916/115675210-af5fcd80-a34e-11eb-9e29-26be9e3e2f4a.png)

## Setup
This assumes you are starting off with a clean NeoVim without any configuration, and you use `~/.config` as your configuration directory.
First install [vim-plug](https://github.com/junegunn/vim-plug). Then:
```sh
?git clone https://github.com/MultisampledNight/configs
?cp -r configs/nvim ~/.config
?nvim
:PlugInstall
:qa
```
Done.

## Dependencies
- [vim-plug](https://github.com/junegunn/vim-plug) as The Plugin Manager
- Phew, that are way too much. You can find all plugins in the `init.vim`.

