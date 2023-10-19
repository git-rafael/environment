{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/release-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.url = "github:nix-community/home-manager/release-23.05";
  };

  outputs = inputs@{ self, nixpkgs, nixpkgs-unstable, home-manager, ... }:

  let
    tooling = import ./packages/tooling.nix;
    security = import ./packages/security.nix;
    operations = import ./packages/operations.nix;
    development = import ./packages/development.nix;

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
          ./home.nix
          {
            home.packages = (tooling env ++ operations env ++ security env ++ development env);

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
    homeConfigurations.mobile = mkDeviceDerivation "aarch64-linux" "null" [];
    homeConfigurations.home = mkDeviceDerivation "x86_64-linux" "root" ["server"];
    homeConfigurations.personal = mkDeviceDerivation "x86_64-linux" "rafael" ["ui"];
    homeConfigurations.professional = mkDeviceDerivation "x86_64-linux" "rafaeloliveira" ["ui" "work"];
  };
}
