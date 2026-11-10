{
  description = "Ambiente de usuário no Debian (home-manager + Nix)";

  # Cache do Hyprland (mesmo do repositório NixOS antigo)
  nixConfig = {
    extra-substituters = [ "https://hyprland.cachix.org" ];
    extra-trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # Sem `follows` no nixpkgs: o cache do cachix é construído com o nixpkgs
    # que o próprio Hyprland fixa, então sobrescrevê-lo derruba o cache.
    hyprland.url = "github:hyprwm/Hyprland/v0.57.1";

    # Envolve os binários gráficos do Nix para usar o Mesa do Nix no Debian
    nixgl = {
      url = "github:nix-community/nixGL";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, home-manager, hyprland, nixgl, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      # Aplicado com: home-manager switch --flake <este diretório>#ely
      homeConfigurations.ely = home-manager.lib.homeManagerConfiguration {
        inherit pkgs;
        extraSpecialArgs = { inherit hyprland nixgl system; };
        modules = [ ./home.nix ];
      };
    };
}
