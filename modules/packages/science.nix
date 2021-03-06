pkgs: with pkgs;
  let
    sciencePython = python39.override {

      packageOverrides = self: super: {

        ipython-sql_prettytable = super.buildPythonPackage rec {
          pname = "prettytable";
          version = "0.7.2";
          doCheck = false;
          src = super.fetchPypi {
            inherit pname version;
            sha256 = "sha256-LVRg3J23SjK8yPn2feaLLE9NLwH6O9UYdkxpFW2crNk=";
          };
        };

        ipython-sql = super.buildPythonPackage rec {
          pname = "ipython-sql";
          version = "0.4.0";
          doCheck = false;
          patches = [ ../../resources/patches/ipython-sql-setup.py ];
          src = super.fetchPypi {
            inherit pname version;
            sha256 = "sha256-PoiOWb9XJ3y9bzg8sjKFiy18cSGeV0klcSjxbZhX5Gw=";
          };
          buildInputs = with super;
            [ six ipython_genutils ipython ];
          propagatedBuildInputs = with super;
            [ sqlalchemy sqlparse self.ipython-sql_prettytable ];
        };

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

    sciencePythonPackages = pythonPkgs: with pythonPkgs; [
      panel
      pandas
      numpy
      scipy
      pyspark
      patsy
      altair
      influxdb
      statsmodels
      scikit-learn
      kafka-python
      ipython-sql
      sqlalchemy
    ];

    localSciencePackages = pythonPkgs: with pythonPkgs; [
      ipython
    ];

    serverSciencePackages = pythonPkgs: with pythonPkgs; [
      jupyterlab
      jupyter_bokeh
      jupyter_http_over_ws
    ];

    localSciencePython = sciencePython.withPackages (pythonPkgs: (localSciencePackages pythonPkgs) ++ (sciencePythonPackages pythonPkgs));
    serverSciencePython = sciencePython.withPackages (pythonPkgs: (serverSciencePackages pythonPkgs) ++ (sciencePythonPackages pythonPkgs));

    sciencePackages = [
      marp
    ];

  in {
    lite = [
      localSciencePython
    ] ++ sciencePackages;

    full = [
      serverSciencePython
    ] ++ sciencePackages;
  }
