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
    deviceMobileDerivation = system: modulePaths:
      nix-on-droid.lib.nixOnDroidConfiguration {
        system = system;
        config.home-manager.config.imports = modulePaths;
    };

    deviceDerivation = system: username: modulePaths:
      home-manager.lib.homeManagerConfiguration {
      system = system;
      username = username;
      homeDirectory = "/home/${username}";
      configuration.imports = modulePaths;
    };

    containerDerivation = modulePath: overrides:
      let 
        module = import modulePath;
        pkgs = import nixpkgs { system="x86_64-linux"; };
      in 
        pkgs.dockerTools.buildImage (module ((builtins.intersectAttrs (builtins.functionArgs module) pkgs) // overrides));

  in {
    nixOnDroidConfigurations.phone = deviceMobileDerivation "aarch64-linux" [
      ./modules/device/base.nix
      ./modules/device/shell.nix
    ];

    homeConfigurations.tablet = deviceDerivation "x86_64-linux" "rafael" [
      ./modules/devices/base.nix
      ./modules/devices/shell.nix
      ./modules/devices/data.nix
      ./modules/devices/systems.nix
      ./modules/devices/science.nix
      ./modules/devices/development.nix
      ./modules/devices/security.nix
      ./modules/devices/code.nix
    ];

    homeConfigurations.notebook = deviceDerivation "x86_64-linux" "rafaeloliveira" [
      ./modules/devices/base.nix
      ./modules/devices/shell.nix
      ./modules/devices/data.nix
      ./modules/devices/systems.nix
      ./modules/devices/science.nix
      ./modules/devices/development.nix
      ./modules/devices/code.nix
    ];

    packages.x86_64-linux.container.automation = containerDerivation ./modules/containers/automation.nix {};
    packages.x86_64-linux.container.laboratory = containerDerivation ./modules/containers/laboratory.nix {};
  };
}
