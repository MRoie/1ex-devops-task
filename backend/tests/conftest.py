import sys
import os
from pathlib import Path

# Add the parent directory to the Python path so tests can import the app package
backend_dir = Path(__file__).parent.parent
sys.path.append(str(backend_dir))