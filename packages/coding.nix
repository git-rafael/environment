pkgs:

let
  python = pkgs.python311.override {
    packageOverrides = self: super: {
      
      jupyter_http_over_ws = super.buildPythonPackage rec {
        pname = "jupyter_http_over_ws";
        version = "0.0.8";
        format = "wheel";
        python = "py2.py3";
        dist = python;
        src = super.fetchPypi {
          inherit pname version format python dist;
          sha256 = "sha256-MFKpSSnZ+0Hk/jP8IsVp6B4Bi5RUqSO9gYWZv2L/2Fo=";
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

		slack
		discord
		spotify

		vscode
	];

in packages
