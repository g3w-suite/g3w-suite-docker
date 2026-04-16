# Override settings for G3W-SUITE docker
# Destination: /code/g3w-admin/base/settings/local_settings.py
# Read connection parameters from environment
import os, sys
from django.conf import settings
from base import __version__ as version

# Load custom templates and static files from your docker volume (eg. "./config/g3w-suite/overrides/")
# --------------------------------------------
# https://docs.djangoproject.com/en/2.2/howto/overriding-templates/
# https://docs.djangoproject.com/en/2.2/howto/static-files/
# https://docs.djangoproject.com/en/2.2/topics/settings/
if( version >= (3, 5) ):
    settings.TEMPLATES[0]['DIRS'].append(os.path.join(settings.BASE_DIR, '../../templates')) # /code/templates
    settings.STATICFILES_DIRS.append(os.path.join(settings.BASE_DIR, '../../static'))        # /code/static

G3WADMIN_PROJECT_APPS = []

G3WADMIN_LOCAL_MORE_APPS = [
    'caching',
    'editing',
    'filemanager',
    'qplotly',
    'qtimeseries',
    'frontend'
]

DATABASES = {
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': os.getenv('G3WSUITE_POSTGRES_DBNAME'),
        'USER': os.getenv('G3WSUITE_POSTGRES_USER_LOCAL') if os.getenv('G3WSUITE_POSTGRES_USER_LOCAL') else "%s@%s" % (
            os.getenv('G3WSUITE_POSTGRES_USER'), os.getenv('G3WSUITE_POSTGRES_HOST')),
        'PASSWORD': os.getenv('G3WSUITE_POSTGRES_PASS'),
        'HOST': os.getenv('G3WSUITE_POSTGRES_HOST'),
        'PORT': os.getenv('G3WSUITE_POSTGRES_PORT'),
    }
}

MEDIA_ROOT = '/shared-volume/media/'
MEDIA_URL = '/media/'
STATIC_ROOT = '/shared-volume/static/'
STATIC_URL = '/static/'

DEBUG = True if os.getenv('G3WSUITE_DEBUG', 'False') == 'True' else False

DATASOURCE_PATH = '/shared-volume/project_data/'

# QGIS AUTH DB
# ========================================
# Set the directory where an existing QGIS auth DB can be found or where it will be created if it does not exist (must be writeable from the server).
QGIS_AUTH_DB_DIR_PATH = os.getenv('G3WSUITE_QGIS_AUTH_DB_DIR_PATH', '/shared-volume')
# Full path to a file where the QGIS auth DB master password is saved, if the file does not exists it will be created (directory must be writeable from the server)
# and the QGIS_AUTH_PASSWORD will be saved into the file.
QGIS_AUTH_PASSWORD_FILE = os.getenv('G3WSUITE_QGIS_AUTH_PASSWORD_FILE', '/shared-volume/qgs_dbauth.db')
# Define QGIS auth DB master password that will be placed into the QGIS_AUTH_PASSWORD_FILE if it does not exist.
QGIS_AUTH_PASSWORD = os.getenv('G3WSUITE_QGIS_AUTH_PASSWORD', 'wtsgTgds53fshUHH89UJY')

# CACHING SETTINGS
# =======================================
TILESTACHE_CACHE_NAME = 'default'
TILESTACHE_CACHE_TYPE = 'Disk'  # or 'Memcache'
TILESTACHE_CACHE_DISK_PATH = os.getenv('G3WSUITE_TILECACHE_PATH', '/shared-volume/tile_cache/')
TILESTACHE_CACHE_BUFFER_SIZE = os.getenv('TILESTACHE_CACHE_BUFFER_SIZE', 256)
TILESTACHE_CACHE_TOKEN = os.getenv('TILESTACHE_CACHE_TOKEN', '374h5g96831hsgetvmkdel')

# FILEMANAGER SETTINGS
# =======================================
FILEMANAGER_ROOT_PATH = os.getenv(
    'G3WSUITE_FILEMANAGER_ROOT_PATH', '/shared-volume/project_data')
FILENAMANAGER_MAX_N_FILES = os.getenv('G3WSUITE_FILENAMANAGER_MAX_N_FILES', 10)

# EDITING SETTINGS
# ======================================
USER_MEDIA_ROOT = FILEMANAGER_ROOT_PATH + '/' + \
    os.getenv('G3WSUITE_USER_MEDIA_ROOT', 'user_media') + '/'


# CACHING
# =======================================
CACHES = {
    "default": {
        "BACKEND": "django_redis.cache.RedisCache",
        "LOCATION": "redis://redis:6379/1",
        "OPTIONS": {
            "CLIENT_CLASS": "django_redis.client.DefaultClient",
        }
    }
}

# HUEY Task scheduler
# Requires redis
# HUEY configuration
HUEY = {
    # Huey implementation to use.
    'huey_class': 'huey.RedisExpireHuey',
    'name': 'g3w-suite',
    'url': 'redis://redis:6379/?db=0',
    'immediate': False if 'run_huey' in sys.argv else os.path.ismount('/code'),  # True = run synchronously.
    'consumer': {
        'workers': 1,
        'worker_type': 'process',
    },
}

USE_X_FORWARDED_HOST = True

ALLOWED_HOSTS = ["*"]

# Is required by caching module
QDJANGO_SERVER_URL = 'http://localhost:8000'

ELASTICSEARCH_DSL = {
    'default': {
        'hosts': os.getenv('G3WSUITE_ELASTIC_HOST', 'http://elasticsearch:9200'),
        #'http_auth': ('username', 'password')
    }
}

LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'filters': {
        'require_debug_false': {
            '()': 'django.utils.log.RequireDebugFalse'
        },
        'require_debug_true': {
            '()': 'django.utils.log.RequireDebugTrue'
        }
    },
    'formatters': {
        'verbose': {
            'format': '%(levelname)s %(asctime)s %(module)s %(process)d %(thread)d %(message)s'
        },
        'simple': {
            'format': '%(levelname)s %(message)s'
        },
    },
    'handlers': {
        'mail_admins': {
            'level': 'ERROR',
            'filters': ['require_debug_false'],
            'class': 'django.utils.log.AdminEmailHandler',
            'formatter': 'verbose'
        },
        'file': {
            'level': 'ERROR',
            'class': 'logging.FileHandler',
            'filename': '/tmp/error.log',
            'formatter': 'verbose'
        },
        'file_debug': {
            'level': 'DEBUG',
            'filters': ['require_debug_true'],
            'class': 'logging.FileHandler',
            'filename': '/tmp/debug.log',
            'formatter': 'verbose'
        },
        'console': {
            'level': 'DEBUG',
            'class': 'logging.StreamHandler',
        },
    },
    'loggers': {
        'django.request': {
            'handlers': ['console', 'mail_admins'],
            'level': 'ERROR',
            'propagate': True,
        },
        'g3wadmin.debug': {
            'handlers': ['console'],
            'level': 'DEBUG',
        },
        'pycsw.server': {
            'handlers': ['console'],
            'level': 'ERROR',
        },
        'django.db.backends': {
            'handlers': ['console'],
            'level': 'ERROR',
        },
        'catalog': {
            'handlers': ['console'],
            'level': 'DEBUG',
        },
        'celery.task': {
            'handlers': ['console'],
            'level': 'DEBUG',
        },
        **({ '': { 'handlers': ['console'], 'level': 'DEBUG' } } if DEBUG  else {}),
    }
}

SESSION_COOKIE_NAME = 'gis3w-suite-dev-iehtgdb264t5gr'

# Set trust url for http
if os.getenv('WEBGIS_PUBLIC_HOSTNAME', None):
    CSRF_TRUSTED_ORIGINS = [
        "http://localhost",
        "http://localhost:8080",
        "http://127.0.0.1",
        "http://127.0.0.1:8080",
        f"http://{os.getenv('WEBGIS_PUBLIC_HOSTNAME', None)}",
        f"http://{os.getenv('WEBGIS_PUBLIC_HOSTNAME', None)}:8080"
    ]
