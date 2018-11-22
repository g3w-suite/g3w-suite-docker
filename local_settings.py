import os
import random
from distutils.util import strtobool

if os.environ.get('G3WSUITE_PROJECT_APPS'):
    G3WADMIN_PROJECT_APPS = os.environ.get('G3WSUITE_PROJECT_APPS').split(',')

G3WADMIN_LOCAL_MORE_APPS = os.environ.get('G3WSUITE_MORE_APPS', None)
if G3WADMIN_LOCAL_MORE_APPS:
    G3WADMIN_LOCAL_MORE_APPS = G3WADMIN_LOCAL_MORE_APPS.split(',')
else:
    G3WADMIN_LOCAL_MORE_APPS = [
        'caching',
    ]

DATABASES = {
    'default': {
        'ENGINE': 'django.contrib.gis.db.backends.postgis',
        'NAME': os.environ.get('G3WSUITE_DATABASE_NAME', 'g3w_admin'),
        'USER': os.environ.get('G3WSUITE_DATABASE_USER', 'postgres'),
        'PASSWORD': os.environ.get('G3WSUITE_DATABASE_PASSWORD', 'postgres'),
        'HOST': os.environ.get('G3WSUITE_DATABASE_HOST', '127.0.0.1'),
        'PORT': os.environ.get('G3WSUITE_DATABASE_PORT', '5432'),
    },
}

DEBUG = strtobool(os.environ.get('G3WSUITE_DEBUG', 'True'))
FRONTEND = strtobool(os.environ.get('G3WSUITE_FRONTEND', 'False'))
#FRONTEND_APP = os.environ.get('G3WSUITE_FRONTEND_APP', 'frontend')

SENTRY = strtobool(os.environ.get('G3WSUITE_SENTRY', 'False'))

SITE_PREFIX_URL = os.environ.get('BASEURL', None)

STATIC_URL = os.environ.get('G3WSUITE_STATIC_URL', '/static/')
STATIC_ROOT = os.environ.get('G3WSUITE_STATIC_ROOT', '/djangoassets/static/')
MEDIA_ROOT = os.environ.get('G3WSUITE_MEDIA_ROOT', '/djangoassets/media/')
MEDIA_URL = os.environ.get('G3WSUITE_MEDIA_URL', '/media/')

DATASOURCE_PATH = os.environ.get('G3WSUITE_DATASOURCE_PATH', '/djangoassets/geodata/')

QDJANGO_SERVER_URL = os.environ.get('G3WSUITE_QDJANGO_SERVER_URL', 'http://localhost/cgi-bin/qgis_mapserv.fcgi')


if 'caching' in G3WADMIN_LOCAL_MORE_APPS:
    TILESTACHE_CACHE_TYPE = os.environ.get('G3WSUITE_TILESTACHE_CACHE_TYPE', 'Disk')
    TILESTACHE_CACHE_DISK_PATH = os.environ.get('G3WSUITE_TILESTACHE_CACHE_DISK_PATH', '/tmp/tilestache_cache/')
    #TILESTACHE_LAYERS_HOST = os.environ.get('G3WSUITE_TILESTACHE_LAYERS_HOSTH', 'http://localhost')
    TILESTACHE_CACHE_NAME = os.environ.get('G3WSUITE_TILESTACHE_CACHE_NAME', 'default')


# for sessions
SESSION_COOKIE_NAME = 'g3wsuite_sessionid{}{}'.format('_' + SITE_PREFIX_URL if SITE_PREFIX_URL else '',
												  random.randint(1, 123456))


LOGGING = {
    'version': 1,
    'disable_existing_loggers': False,
    'filters': {
        'require_debug_false': {
            '()': 'django.utils.log.RequireDebugFalse'
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
            'class': 'logging.FileHandler',
            'filename': '/tmp/debug.log',
            'formatter': 'verbose'
        },
    },
    'loggers': {
        'django.request': {
            'handlers': ['file', 'mail_admins'],
            'level': 'ERROR',
            'propagate': True,
        },
        'timon.debug': {
            'handlers': ['file_debug'],
            'level': 'DEBUG',
        },
    }
}