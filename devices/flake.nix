{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  };
  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations."AMININT-503325" = nixpkgs.lib.nixosSystem {
      specialArgs = { inherit inputs; };
      system = "x86_64-linux";
      modules = [
        ./AMININT-503325/configuration.nix
      ];
    };
  };
}
