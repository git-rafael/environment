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

    toolboxDerivation = modulePath: overrides:
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
      ./modules/device/base.nix
      ./modules/device/shell.nix
      ./modules/device/data.nix
      ./modules/device/systems.nix
      ./modules/device/science.nix
      ./modules/device/development.nix
      ./modules/device/security.nix
      ./modules/device/code.nix
    ];

    homeConfigurations.notebook = deviceDerivation "x86_64-linux" "rafaeloliveira" [
      ./modules/device/base.nix
      ./modules/device/shell.nix
      ./modules/device/data.nix
      ./modules/device/systems.nix
      ./modules/device/science.nix
      ./modules/device/development.nix
      ./modules/device/code.nix
    ];

    packages.x86_64-linux.toolbox.automation = toolboxDerivation ./modules/toolbox/automation.nix {};
    packages.x86_64-linux.toolbox.laboratory = toolboxDerivation ./modules/toolbox/laboratory.nix {};
  };
}
