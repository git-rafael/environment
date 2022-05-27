diff --git a/setup.py b/setup.py
index e4a653d..d8f7511 100644
--- a/setup.py
+++ b/setup.py
@@ -4,7 +4,7 @@ import os
 
 here = os.path.abspath(os.path.dirname(__file__))
 README = open(os.path.join(here, 'README.rst'), encoding='utf-8').read()
-NEWS = open(os.path.join(here, 'NEWS.rst'), encoding='utf-8').read()
+NEWS = ''
 
 
 version = '0.4.0'
