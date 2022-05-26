pkgs: with pkgs;
	let
		pythonPkgs = python38Packages.override {

			overrides = self: super: {

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
						[ six sqlalchemy sqlparse self.ipython-sql_prettytable ipython_genutils ipython ];
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

		laboratoryPythonPackages = python-packages: [
			pythonPkgs.jupyterlab
			pythonPkgs.panel
			pythonPkgs.pyspark
			pythonPkgs.pandas
			pythonPkgs.numpy
			pythonPkgs.scipy
			pythonPkgs.patsy
			pythonPkgs.altair
			pythonPkgs.influxdb
			pythonPkgs.statsmodels
			pythonPkgs.scikit-learn
			pythonPkgs.kafka-python
			pythonPkgs.jupyter_http_over_ws
			pythonPkgs.jupyter_bokeh
			pythonPkgs.ipython-sql
			pythonPkgs.ipython
		]; 

		laboratoryPython = python3.withPackages laboratoryPythonPackages;

	in [
		marp
		laboratoryPython
	]
