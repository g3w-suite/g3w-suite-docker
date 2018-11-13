import os
import random
from distutils.util import strtobool

if os.environ.get('G3WSUITE_PROJECT_APPS'):
    G3WADMIN_PROJECT_APPS = os.environ.get('G3WSUITE_PROJECT_APPS').split(',')

G3WADMIN_LOCAL_MORE_APPS = os.environ.get('G3WSUITE_MORE_APPS', None)
if G3WADMIN_LOCAL_MORE_APPS:
    G3WADMIN_LOCAL_MORE_APPS = G3WADMIN_LOCAL_MORE_APPS.split(',')
else:
    G3WADMIN_LOCAL_MORE_APPS = []

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

#STATIC_URL = '{}/static/'.format('/' + SITE_PREFIX_URL if SITE_PREFIX_URL else '')
STATIC_ROOT = '/home/g3wsuite/static/'
#MEDIA_ROOT = '/home/g3wsuite/media/'
#MEDIA_URL = '{}/media/'.format('/' + SITE_PREFIX_URL if SITE_PREFIX_URL else '')

DATASOURCE_PATH = '/home/g3wsuite/data/'

'''
if 'caching' in G3WADMIN_LOCAL_MORE_APPS:
    TILESTACHE_CACHE_TYPE = os.environ.get('G3WSUITE_TILESTACHE_CACHE_TYPE', 'Disk')
    TILESTACHE_CACHE_DISK_PATH = os.environ.get('G3WSUITE_TILESTACHE_CACHE_DISK_PATH', '/tmp/tilestache_cache/')
    TILESTACHE_LAYERS_HOST = os.environ.get('G3WSUITE_TILESTACHE_LAYERS_HOSTH', 'http://localhost')
'''

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