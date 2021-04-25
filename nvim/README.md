# NeoVims configuration
I use both normal NeoVim as well as NeoVim Nightly. I adjusted my init.vim to work with both.

**IMPORTANT NOTE:** If you plan to use both normal and nightly NeoVim as well, install the Plugins first with NeoVim Nightly. Don't execute `:PlugClean` in the normal NeoVim.

## Images

![Full size image of my NeoVim setup](https://user-images.githubusercontent.com/80128916/116002001-c8d77280-a5f7-11eb-84a3-c24fce62ba73.png)

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

