{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, ... }:

  let
    tooling = import ./packages/tooling.nix;
    security = import ./packages/security.nix;
    operations = import ./packages/operations.nix;
    development = import ./packages/development.nix;

    mkDeviceDerivation = system: username: profile: home-manager.lib.homeManagerConfiguration rec {
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.allowUnsupportedSystem = true;
      };

      modules = [
        ./home.nix
        {
          home.packages = (tooling pkgs ++ operations pkgs ++ security pkgs ++ development pkgs);

          home.homeDirectory =
            if username == "null" then "/home"
            else if username == "root" then "/root"
            else "/home/${username}";

          home.username = username;
          home.stateVersion = "22.11";
          programs.home-manager.enable = true;
          targets.genericLinux.enable = true;
        }
      ];
    };

  in {
    homeConfigurations.home = mkDeviceDerivation "x86_64-linux" "root";
    homeConfigurations.mobile = mkDeviceDerivation "aarch64-linux" "null";
    homeConfigurations.personal = mkDeviceDerivation "x86_64-linux" "rafael";
    homeConfigurations.professional = mkDeviceDerivation "x86_64-linux" "rafaeloliveira";
  };
}
