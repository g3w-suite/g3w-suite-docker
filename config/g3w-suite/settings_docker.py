# Override settings for G3W-SUITE docker
# Destination: /code/g3w-admin/base/settings/local_settings.py
# Read connection parameters from environment
import os

G3WADMIN_PROJECT_APPS = []

G3WADMIN_LOCAL_MORE_APPS = [
    'caching',
    'editing',
    'filemanager',
    'qplotly',
    'qtimeseries',
    # Uncomment if you wont activate the following module
    #'openrouteservice',
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

DEBUG = False if os.getenv('G3WSUITE_DEBUG', 0) == 0 else True

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


# OPENROUTESERVICE SETTINGS
# ===============================
# settings for 'openrouteservice' module is in 'G3WADMIN_LOCAL_MORE_APPS'
# ORS API endpoint
ORS_API_ENDPOINT = os.getenv('ORS_API_ENDPOINT', 'https://api.openrouteservice.org/v2')
# Optional, can be blank if the key is not required by the endpoint
ORS_API_KEY = os.getenv('ORS_API_KEY', '')
# List of available ORS profiles
ORS_PROFILES = {
    "driving-car": {"name": "Car"},
    "driving-hgv": {"name": "Heavy Goods Vehicle"}
}
# Max number of ranges (it depends on the server configuration)
ORS_MAX_RANGES = int(os.getenv('ORS_MAX_RANGES', 6))
# Max number of locations(it depends on the server configuration)
ORS_MAX_LOCATIONS = int(os.getenv('ORS_MAX_LOCATIONS', 2))

# HUEY Task scheduler
# Requires redis
# HUEY configuration
HUEY = {
    # Huey implementation to use.
    'huey_class': 'huey.RedisExpireHuey',
    'name': 'g3w-suite',
    'url': 'redis://redis:6379/?db=0',
    'immediate': False,  # If DEBUG=True, run synchronously.
    'consumer': {
        'workers': 1,
        'worker_type': 'process',
    },
}

ALLOWED_HOSTS = "*"

# Is required by caching module
QDJANGO_SERVER_URL = 'http://localhost:8000'

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
        'openrouteservice': {
            'handlers': ['console'],
            'level': 'DEBUG',
        }
    }
}

SESSION_COOKIE_NAME = 'gi3w-suite-dev-iehtgdb264t5gr'
