{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, ... }:

  let
    development = import ./packages/development.nix;
    operations = import ./packages/operations.nix;
    security = import ./packages/security.nix;

    utilities = import ./packages/utilities.nix;

    mkDeviceDerivation = system: username: features: home-manager.lib.homeManagerConfiguration rec {
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
        config.allowUnsupportedSystem = true;
      };

      modules = 
        let
          edgePkgs = import nixpkgs-unstable {
            inherit system;
            config.allowUnfree = true;
            config.allowUnsupportedSystem = true;
          };
          env = { inherit pkgs edgePkgs features; };
        in [
          ./shell.nix
          {
            home.packages = (development env ++ operations env ++ security env ++ utilities env);

            home.homeDirectory =
              if username == "null" then "/home"
              else if username == "root" then "/root"
              else "/home/${username}";

            home.username = username;
            home.stateVersion = "23.05";
            programs.home-manager.enable = true;
            targets.genericLinux.enable = true;
          }
        ];
    };

  in {
    homeConfigurations.termux = mkDeviceDerivation "aarch64-linux" "null" ["work"];
    homeConfigurations.ha-terminal = mkDeviceDerivation "x86_64-linux" "root" ["server"];
    homeConfigurations.crostini-penguin = mkDeviceDerivation "x86_64-linux" "rafael" ["ui"];
    homeConfigurations.crostini-puffin = mkDeviceDerivation "x86_64-linux" "rafaeloliveira" ["ui" "work"];
  };
}
