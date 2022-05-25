{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-21.11";
    
    home-manager.url = "github:nix-community/home-manager/release-21.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    nix-on-droid.url = "github:t184256/nix-on-droid";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "home-manager";
  };

  outputs = { self, nixpkgs, home-manager, nix-on-droid, ... }:

  let
    mkDeviceMobileDerivation = system: modulePaths: nix-on-droid.lib.nixOnDroidConfiguration {
        system = system;
        config.home-manager.config.imports = modulePaths;
    };

    mkDeviceDerivation = system: username: modulePaths: home-manager.lib.homeManagerConfiguration {
      system = system;
      username = username;
      homeDirectory = "/home/${username}";
      configuration.imports = modulePaths;
    };

    mkContainerDerivation = modulePath:
      let 
        module = import modulePath;
        pkgs = import nixpkgs { system="x86_64-linux"; };
      in pkgs.dockerTools.buildImage (module (builtins.intersectAttrs (builtins.functionArgs module) pkgs home-manager));

  in {
    nixOnDroidConfigurations.phone = mkDeviceMobileDerivation "aarch64-linux" [
      ./modules/profiles/base.nix
      ./modules/profiles/shell.nix
    ];

    homeConfigurations.tablet = mkDeviceDerivation "x86_64-linux" "rafael" [
      ./modules/profiles/base.nix
      ./modules/profiles/shell.nix
      ./modules/profiles/data.nix
      ./modules/profiles/systems.nix
      ./modules/profiles/science.nix
      ./modules/profiles/development.nix
      ./modules/profiles/security.nix
      ./modules/profiles/code.nix
    ];

    homeConfigurations.notebook = mkDeviceDerivation "x86_64-linux" "rafaeloliveira" [
      ./modules/profiles/base.nix
      ./modules/profiles/shell.nix
      ./modules/profiles/data.nix
      ./modules/profiles/systems.nix
      ./modules/profiles/science.nix
      ./modules/profiles/development.nix
      ./modules/profiles/code.nix
    ];

    packages.x86_64-linux.container.automation = mkContainerDerivation ./modules/containers/automation.nix;
    packages.x86_64-linux.container.laboratory = mkContainerDerivation ./modules/containers/laboratory.nix;
  };
}
