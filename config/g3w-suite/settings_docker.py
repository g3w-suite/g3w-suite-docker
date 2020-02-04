# Override settings for G3W-SUITE docker
# Destination: /code/g3w-admin/base/settings/local_settings.py
# Read connection parameters from environment

import os

G3WADMIN_PROJECT_APPS = []

G3WADMIN_LOCAL_MORE_APPS = [
    'caching',
    'editing'
]

DATABASES = {
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': os.getenv('G3WSUITE_POSTGRES_DBNAME'),
        'USER': os.getenv('G3WSUITE_POSTGRES_USER_LOCAL') if os.getenv('G3WSUITE_POSTGRES_USER_LOCAL') else "%s@%s" % (os.getenv('G3WSUITE_POSTGRES_USER'), os.getenv('G3WSUITE_POSTGRES_HOST')),
        'PASSWORD': os.getenv('G3WSUITE_POSTGRES_PASS'),
        'HOST': os.getenv('G3WSUITE_POSTGRES_HOST'),
        'PORT': os.getenv('G3WSUITE_POSTGRES_PORT'),
    }
}



MEDIA_ROOT = '/shared-volume/media/'
MEDIA_URL = '/media/'
STATIC_ROOT = '/shared-volume/static/'
STATIC_URL = '/static/'

DEBUG = False

QDJANGO_SERVER_URL = os.getenv('G3WSUITE_QDJANGO_SERVER_URL')

DATASOURCE_PATH = '/shared-volume/project_data/'

# CACHING SETTINGS
# =======================================
TILESTACHE_CACHE_NAME = 'default'
TILESTACHE_CACHE_TYPE = 'Disk' # or 'Memcache'
TILESTACHE_CACHE_DISK_PATH = os.getenv('G3WSUITE_TILECACHE_PATH')
TILESTACHE_CACHE_BUFFER_SIZE = os.getenv('TILESTACHE_CACHE_BUFFER_SIZE')  # Pixels

ALLOWED_HOSTS = "*"

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
        '': {
            'handlers': ['console'],
            'level': 'WARNING',
        }
    }
}

SESSION_COOKIE_NAME = 'gi3w-suite-dev-iehtgdb264t5gr'



