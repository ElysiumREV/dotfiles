# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      <home-manager/nixos>    
    ];

  system.autoUpgrade = {
    enable = true;
    allowReboot = false;
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Display Manager
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
    theme = "sddm-astronaut-theme";
    extraPackages = [ pkgs.sddm-astronaut ];
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true; # if not already enabled
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    wireplumber.enable = true;
    # If you want to use JACK applications, uncomment the following
    #jack.enable = true;
  };


  networking.hostName = "elysium"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Sao_Paulo";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "pt_BR.UTF-8";
    LC_IDENTIFICATION = "pt_BR.UTF-8";
    LC_MEASUREMENT = "pt_BR.UTF-8";
    LC_MONETARY = "pt_BR.UTF-8";
    LC_NAME = "pt_BR.UTF-8";
    LC_NUMERIC = "pt_BR.UTF-8";
    LC_PAPER = "pt_BR.UTF-8";
    LC_TELEPHONE = "pt_BR.UTF-8";
    LC_TIME = "pt_BR.UTF-8";
  };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "altgr-intl";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.ely = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
  };

  programs.zsh.enable = true;

  # Home Manager / Configuracoes da home do usuario
  home-manager.users.ely = { pkgs, ... }: {
    home.packages = [ pkgs.atool pkgs.httpie ];
    programs.zsh = {
      enable = true;
      enableCompletion = true;
      autosuggestion.enable = true;
      syntaxHighlighting.enable = true;
      history.size = 10000;

      shellAliases = {
        ll = "ls -l";
        edit = "sudo -e";
        update = "sudo nixos-rebuild switch";
      };

      oh-my-zsh = {
        enable = true;
        theme = "lambda";
        plugins = [ "git" ];
      };
    };

    home.pointerCursor = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };

    # This value determines the Home Manager release that your configuration is
    # compatible with. This helps avoid breakage when a new Home Manager release
    # introduces backwards incompatible changes.
    #
    # You should not change this value, even if you update Home Manager. If you do
    # want to update the value, then make sure to first check the Home Manager
    # release notes.
    home.stateVersion = "25.11"; # Please read the comment before changing. 
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    kitty
    waybar
    wofi
    wofi-emoji
    hyprpaper
    hyprlock
    hypridle
    hyprsunset
    hyprpolkitagent
    (discord.override {
      withOpenASAR = true; # can do this here too
      withVencord = true;
    })
    vesktop
    firefox
    bitwarden-desktop
    git
    p7zip
    neovim
    pavucontrol
    fastfetch
    vlc
    ffmpeg-full
    unzip
    mpd
    mpv
    yazi
    wlogout
    mako
    sddm-astronaut
    cliphist
    wl-clipboard
    grim
    slurp
    materia-theme
    materia-kde-theme
    papirus-icon-theme
    libsForQt5.qt5ct
    kdePackages.qt6ct
    kdePackages.qtstyleplugin-kvantum
    vscode
    protonvpn-gui
    wineWowPackages.staging
    winetricks
    networkmanagerapplet
    obsidian
    prismlauncher
    pcmanfm-qt
    gcc
    btop
    telegram-desktop
    rar
    pear-desktop
    asdf-vm
    _7zz-rar
    gamemode
    libreoffice-fresh
    qbittorrent
    gimp
    protontricks
    euphonica
    nodejs_22
    clang-tools
    cmake
    codespell
    conan
    cppcheck
    doxygen
    gtest
    lcov
    vcpkg
    vcpkg-tool
    gpu-screen-recorder-gtk
    jdk21
    jetbrains.idea
    postman
  ];

  virtualisation.docker = {
    enable = true;
  };

  environment.variables = {
      SUDO_EDITOR = "nvim";
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

  environment.sessionVariables = {
      # XDG
      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
      XDG_SESSION_DESKTOP = "Hyprland";

      # Terminal
      TERMINAL = "kitty";

      # Qt
      QT_QPA_PLATFORM = "wayland;xcb";
      QT_QPA_PLATFORMTHEME = "qt5ct";
      QT_STYLE_OVERRIDE = "kvantum";
      QT_WAYLAND_DISABLE_WINDOWDECORATION = "1";
      QT_AUTO_SCREEN_SCALE_FACTOR = "1";

      # Electron
      ELECTRON_OZONE_PLATFORM_HINT = "wayland";
  
      # Ozone (for Firefox/Chromium)
      NIXOS_OZONE_WL = "1";
  
      # GTK
      GDK_BACKEND = "wayland,x11";
  
      # SDL
      SDL_VIDEODRIVER = "wayland";
  
      # Clutter
      CLUTTER_BACKEND = "wayland";
    };

  services.gvfs.enable = true;
  services.gnome.gnome-keyring.enable = true;
  security.pam.services.sddm.enableGnomeKeyring = true;
  security.pam.services.hyprland.enableGnomeKeyring = true;

  programs.gpu-screen-recorder.enable = true; 

  programs.dconf.profiles.user.databases = [
    {
      settings."org/gnome/desktop/interface" = {
        lockAll = true;
        gtk-theme = "Materia-dark";
        icon-theme = "Papirus";
        font-name = "JetBrainsMono Medium 11";
        document-font-name = "JetBrainsMono Medium 11";
        monospace-font-name = "JetBrains Mono Medium 11";
        color-scheme = "prefer-dark";
      };
    }
  ];

  qt = {
    enable = true;
    platformTheme = "qt5ct";
    style = "kvantum";
  };

  fonts.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    freetype
  ];

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
  };

  programs.hyprland = {
    enable = true;
    withUWSM = false;
    xwayland.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = with pkgs; [ 
      xdg-desktop-portal-hyprland
      xdg-desktop-portal-gtk
    ];
  };

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  services.flatpak.enable = true;

  programs.appimage = {
    enable = true;
    binfmt = true;
  };

  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc
    zlib
    openssl
    curl
  ];
  services.syncthing = {
    enable = true;
    user = "ely";
    group = "users";
    openDefaultPorts = true;
    dataDir = "/home/ely";
  };

  programs.obs-studio = {
    enable = true;

    # optional Nvidia hardware acceleration
    #package = (
    #  pkgs.obs-studio.override {
    #    cudaSupport = true;
    #  }
    #);

    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vaapi #optional AMD hardware acceleration
      obs-gstreamer
      obs-vkcapture
    ];
  };
# Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.11"; # Did you read the comment?

  fileSystems."/mnt/HDD" = {
    device = "/dev/disk/by-uuid/5c180f20-d517-42b0-a400-d15ca0f9ca96";
    fsType = "ext4";
    options = [ "defaults" "nofail" "x-gvfs-show" ];
  };

  fileSystems."/mnt/SSD" = {
    device = "/dev/disk/by-uuid/e39f2392-a208-4374-8eb4-cb982b618d00";
    fsType = "ext4";
    options = [ "defaults" "nofail" "x-gvfs-show" ];
  };

}

