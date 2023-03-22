pkgs:

let
  dind = pkgs.writeShellScriptBin "dind" (builtins.readFile ../resources/scripts/dind);
  using = pkgs.writeShellScriptBin "using" (builtins.readFile ../resources/scripts/using);

  python = pkgs.python311.override {
    packageOverrides = self: super: {
      
      jupyter_http_over_ws = super.buildPythonPackage rec {
        pname = "jupyter_http_over_ws";
        version = "0.0.8";
        doCheck = false;
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "sha256-sKoeeQLTgIppjUhT9t/hL9AqDZyzhR2zv1lwMQbUSoA=";
        };
        buildInputs = with super;
          [ jupyter-packaging notebook ];
      };
      
      jupyter_bokeh = super.buildPythonPackage rec {
        pname = "jupyter_bokeh";
        version = "3.0.3";
        doCheck = false;
        src = super.fetchPypi {
          inherit pname version;
          sha256 = "sha256-TEoGw/bF2SDINXaBvupXKXs9bR1GuCwpBFCIuW+dSwE=";
        };
        buildInputs = with super;
          [ jupyter-packaging ipywidgets bokeh ];
      };
    };
  };

  pythonPackages = python.withPackages (
    pythonPkgs: with pythonPkgs; [
      ipython
      ipython-sql
      jupyterlab
      jupyter_bokeh
      jupyter_http_over_ws
    ]
  );

  packages = with pkgs; [
    pythonPackages

    devbox
    tldr
    gh

    docker-client
    docker-compose

    podman
    podman-compose

    git-crypt

    goss
    dgoss

    dind
    using

    packer
    terraform
  ];

in packages
