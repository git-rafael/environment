{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-21.11";
    
    home-manager.url = "github:nix-community/home-manager/release-21.11";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    
    nix-on-droid.url = "github:t184256/nix-on-droid";
    nix-on-droid.inputs.nixpkgs.follows = "nixpkgs";
    nix-on-droid.inputs.home-manager.follows = "home-manager";
  };

  outputs = inputs@{ self, nixpkgs, home-manager, nix-on-droid, ... }:

  let
    mkDeviceMobileDerivation = system: modulePaths: nix-on-droid.lib.nixOnDroidConfiguration {
        inherit system;
        config.home-manager.config.imports = modulePaths;
    };

    mkDeviceDerivation = system: username: modulePaths: home-manager.lib.homeManagerConfiguration {
      inherit system username;
      configuration.imports = modulePaths;
      homeDirectory = if username == "root" then "/root" else "/home/${username}";
    };

    mkContainerDerivation = system: modulePath:
      let systemPkgs = import nixpkgs { inherit system; };
      in systemPkgs.dockerTools.buildImage (import modulePath { pkgs = systemPkgs; });

  in {
    nixOnDroidConfigurations.mobile = mkDeviceMobileDerivation "aarch64-linux" [
      ./modules/profiles/base.nix
      ./modules/profiles/shell.nix
      ./modules/profiles/data.nix
      ./modules/profiles/systems.nix
    ];

    homeConfigurations.personal = mkDeviceDerivation "x86_64-linux" "rafael" [
      ./modules/profiles/base.nix
      ./modules/profiles/shell.nix
      ./modules/profiles/data.nix
      ./modules/profiles/systems.nix
      ./modules/profiles/security.nix
      ./modules/profiles/code-science.nix
      ./modules/profiles/code-development.nix
    ];

    homeConfigurations.professional = mkDeviceDerivation "x86_64-linux" "rafaeloliveira" [
      ./modules/profiles/base.nix
      ./modules/profiles/shell.nix
      ./modules/profiles/data.nix
      ./modules/profiles/systems.nix
      ./modules/profiles/code-science.nix
      ./modules/profiles/code-development.nix
    ];

    homeConfigurations.home = mkDeviceDerivation "x86_64-linux" "root" [
      ./modules/profiles/base.nix
      ./modules/profiles/shell.nix
      ./modules/profiles/data.nix
      ./modules/profiles/systems.nix
      ./modules/profiles/security.nix
      ./modules/profiles/science.nix
      ./modules/profiles/development.nix
    ];

    packages.x86_64-linux.container.python = mkContainerDerivation "x86_64-linux" ./modules/containers/python.nix;
    packages.x86_64-linux.container.javascript = mkContainerDerivation "x86_64-linux" ./modules/containers/javascript.nix;
    packages.x86_64-linux.container.java = mkContainerDerivation "x86_64-linux" ./modules/containers/java.nix;
    packages.x86_64-linux.container.dotnet = mkContainerDerivation "x86_64-linux" ./modules/containers/dotnet.nix;
  };
}
