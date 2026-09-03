import os

DEBUG = os.getenv('G3WSUITE_DEBUG', 'False') == 'True'

if DEBUG:
    try:
        import debugpy
        debugpy.listen(("0.0.0.0", 5678))
        print("--- Debugger listening on port 5678 ---")
    except ImportError:
        print("--- Debug.py not installed: skipping ---")
    except Exception as e:
        print(f"Debugger error: {e}")

from base.wsgi import application