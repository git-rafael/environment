diff --git a/setup.py b/setup.py
index e4a653d..70e98ad 100644
--- a/setup.py
+++ b/setup.py
@@ -1,8 +1,9 @@
 from io import open
 from setuptools import setup, find_packages
 import os
+from pathlib import Path
 
-here = os.path.abspath(os.path.dirname(__file__))
+here = Path(__file__).parent.resolve()
 README = open(os.path.join(here, 'README.rst'), encoding='utf-8').read()
 NEWS = open(os.path.join(here, 'NEWS.rst'), encoding='utf-8').read()
 
