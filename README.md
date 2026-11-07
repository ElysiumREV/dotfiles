# Elysium's dotfiles for Hyprland

### These dotfiles are specifically made for my use and i use github just for backup purpose, i don't guarantee they'll work for you out of the box and i don't intend to.

### Features
<ul>
<li> Hyprland – Wayland compositor (Lua config), with hypridle, hyprlock and uwsm
<li> Quickshell – bar, launcher, notifications, quick-settings panel (Wi-Fi, Bluetooth, mixer, battery), clipboard history, screenshots, screen recording (gpu-screen-recorder), wallpaper picker and Wallhaven search
<li> Matugen – Material 3 colors generated from the wallpaper and applied to Quickshell, Hyprland, hyprlock, GTK/Qt, Kitty, Neovim, Zed and more
<li> Kitty – Terminal emulator with custom color schemes
<li> Neovim – Configured with lazy.nvim and plugins
</ul>

### How it works

- `configurations/` mirrors the files listed in `backup.conf` (paths relative to `$HOME`). Run `./backup.sh` to copy the current system files into it; generated files (see `backup.exclude`) keep their last committed version unless you pass `--all`.
- `install.sh` (Arch/CachyOS) and `install_fedora.sh` (Fedora, secondary) install the packages and copy `configurations/` into `$HOME`.
- Changing the wallpaper in Quickshell (`SUPER+W`) runs `~/.config/quickshell/scripts/apply_colors.sh`: Matugen only generates the color files, and that script reloads every application.
- The Quickshell UI, logs and code comments are in English. Its design notes live in `configurations/home/ely/.config/quickshell/DIARIO_DO_QUICKSHELL.md` (Portuguese).
- After changing the Quickshell config, run `~/.config/quickshell/scripts/smoke-test.sh` inside the session: it opens every panel and fails if the log shows QML errors.

### License

#### Most part of the installer script was vibecoded so it's your responsibility to understand what it does and modify it as needed, as said before, i don't guarantee it'll work for you out of the box.

These dotfiles are free to use, modify, and share. Wallpapers may have different copyrights, i got all the wallpapers from wallhaven.cc — check before redistribution.

My dotfiles are heavily inspired and by some very cool shell setup i've seen like the [Caelestia Shell](https://github.com/caelestia-dots/shell) and [end-4](https://github.com/end-4/dots-hyprland), i find those two specially really beautiful and cool so i tried to make some features i've seen on them.
