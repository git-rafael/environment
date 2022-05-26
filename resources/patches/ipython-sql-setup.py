--- setup.py	2022-05-26 14:01:23.185934840 -0300
+++ setup_new.py	2022-05-26 14:02:27.785933400 -0300
@@ -1,9 +1,10 @@
 import os
 from io import open
+from pathlib import Path
 
 from setuptools import find_packages, setup
 
-here = os.path.abspath(os.path.dirname(__file__))
+here = Path(__file__).parent.resolve()
 README = open(os.path.join(here, "README.rst"), encoding="utf-8").read()
 NEWS = open(os.path.join(here, "NEWS.rst"), encoding="utf-8").read()
 
