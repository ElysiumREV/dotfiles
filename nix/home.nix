{ config, pkgs, hyprland, nixgl, system, ... }:

{
  # --- USUÁRIO ---
  home.username = "ely";
  home.homeDirectory = "/home/ely";
  home.stateVersion = "25.11";
  programs.home-manager.enable = true;

  # --- NIXGL (Mesa do Nix em cima do Debian) ---
  targets.genericLinux.enable = true;
  targets.genericLinux.nixGL.packages = nixgl.packages.${system};

  fonts.fontconfig.enable = true;

  # --- SESSÃO HYPRLAND E QUICKSHELL (sempre atualizados pelo flake) ---
  home.packages = with pkgs; [
    (config.lib.nixGL.wrap hyprland.packages.${system}.hyprland)
    (config.lib.nixGL.wrap quickshell)
    hyprlock
    hypridle
    hyprsunset
    hyprpicker
    hyprpolkitagent
    awww
    matugen
  ]

  # --- FERRAMENTAS DE TERMINAL ---
  ++ (with pkgs; [
    neovim
    starship
    eza
    fastfetch
    btop
    lazygit
    ripgrep
    fd
    nodejs
    imagemagick
  ])

  # --- FONTES ---
  ++ [
    pkgs.nerd-fonts.jetbrains-mono
  ];
}
