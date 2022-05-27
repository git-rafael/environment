pkgs: with pkgs;
  let
    javaPackages = import ../java.nix pkgs;
    dotnetPackages = import ../dotnet.nix pkgs;
    pythonPackages = import ../python.nix pkgs;
    javascriptPackages = import ../javascript.nix pkgs;

    packages = with pkgs; [
      tldr
      
      docker-client
      docker-compose

      podman
      podman-compose

      git-crypt
      git-hound

      pritunl-ssh

      goss
      dgoss
    ];

  in {
    lite = packages;

    full = lite ++ javaPackages ++ dotnetPackages ++ pythonPackages ++ javascriptPackages;
  }
