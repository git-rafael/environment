diff --git a/setup.py b/setup.py
index 354cdab..22cc24e 100644
--- a/setup.py
+++ b/setup.py
@@ -1,9 +1,10 @@
 import os
 from io import open
+from pathlib import
 
 from setuptools import find_packages, setup
 
-here = os.path.abspath(os.path.dirname(__file__))
+here = Path(__file__).parent.resolve()
 README = open(os.path.join(here, "README.rst"), encoding="utf-8").read()
 NEWS = open(os.path.join(here, "NEWS.rst"), encoding="utf-8").read()
 
