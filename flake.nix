{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-24.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-24.05";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, ... }:

  let
    development = import ./sources/development.nix;
    operation = import ./sources/operation.nix;
    security = import ./sources/security.nix;
    utility = import ./sources/utility.nix;
    shell = import ./sources/shell.nix;

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
          
          developmentInstallation = (development env);
          operationInstallation = (operation env);
          securityInstallation = (security env);
          utilityInstallation = (utility env);
          shellInstallation = (shell env);
        in [
          developmentInstallation
          operationInstallation
          securityInstallation
          utilityInstallation
          shellInstallation
          {
            home.homeDirectory =
              if username == "null" then "/home"
              else if username == "root" then "/root"
              else "/home/${username}";

            home.username = username;
            home.stateVersion = "24.05";
            targets.genericLinux.enable = true;
            programs.home-manager.enable = true;
          }
        ];
    };

  in {
    homeConfigurations.phone = mkDeviceDerivation "aarch64-linux" "null" ["work"];
    homeConfigurations.notebook = mkDeviceDerivation "x86_64-linux" "rafael" ["ui"];
    homeConfigurations.ha-terminal = mkDeviceDerivation "x86_64-linux" "root" ["server"];
    homeConfigurations.crostini-penguin = mkDeviceDerivation "x86_64-linux" "rafael" ["ui"];
    homeConfigurations.crostini-puffin = mkDeviceDerivation "x86_64-linux" "rafaeloliveira" ["ui" "work"];
  };
}
