pkgs: with pkgs;
  let
    javaPackages = import ./java.nix pkgs;
    dotnetPackages = import ./dotnet.nix pkgs;
    pythonPackages = import ./python.nix pkgs;
    javascriptPackages = import ./javascript.nix pkgs;

    dind = pkgs.writeShellScriptBin "dind" (builtins.readFile ../../resources/scripts/dind);
    using = pkgs.writeShellScriptBin "using" (builtins.readFile ../../resources/scripts/using);

    packages = with pkgs; [
      coreutils
      findutils
      cifs-utils

      asdf-vm
      tldr

      docker-client
      docker-compose

      podman
      podman-compose

      git-crypt
      git-hound

      goss
      dgoss

      dind
      using
    ];

  in {
    lite = packages;

    full = packages ++ javaPackages ++ dotnetPackages ++ pythonPackages ++ javascriptPackages;
  }
