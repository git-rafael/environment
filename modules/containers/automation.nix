{ nixpkgs, home-manager, deviceDerivation, ... } : 
let
  pkgs = import nixpkgs { system="x86_64-linux"; };
in {
  fromImage = pkgs.dockerTools.pullImage {
    imageName = "nixos/nix";
    imageDigest = "sha256:85299d86263a3059cf19f419f9d286cc9f06d3c13146a8ebbb21b3437f598357";
    sha256 = "19fw0n3wmddahzr20mhdqv6jkjn1kanh6n2mrr08ai53dr8ph5n7";
    finalImageTag = "2.2.1";
    finalImageName = "nix";
  };

  name = "environment";
  tag = "automation";

  contents = deviceDerivation;

  config = {
    Cmd = [ "env-shell" ];
  };
}
