{ config, lib, pkgs, ... }:

let
  packages = with pkgs; [
    marp
  ] ++ (with pkgs.python3Packages; [
    jupyterlab
    panel
    jupyter_bokeh
    ipython-sql
    pandas
    altair
    influxdb
    kafka-python
    scikit-learn
  ]) ++ (with pkgs.pypyPackages; [
    jupyter_http_over_ws
  ]);

in {
  home.packages = packages;
}
