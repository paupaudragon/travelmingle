from django.core.wsgi import get_wsgi_application
import os
import sys

# Add the project directory to sys.path
path = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if path not in sys.path:
    sys.path.append(path)

# Set Django settings module
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

# Import Django WSGI application
application = get_wsgi_application()
