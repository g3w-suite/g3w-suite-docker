import ast
import json
import logging
import os
import re

import docker

from invoke import run, task

BOOTSTRAP_IMAGE_CHEIP = 'codenvy/che-ip:nightly'

FIXTURES = [
    'BaseLayer.json',
    'G3WGeneralDataSuite.json',
    'G3WMapControls.json',
    'G3WSpatialRefSys.json'
]


@task
def waitfordbs(ctx):
    print "**************************databases*******************************"
    ctx.run("/usr/bin/wait-for-databases {0}".format('db'), pty=True)


@task
def migrations(ctx):
    print "**************************migrations*******************************"
    ctx.run("g3w-admin/manage.py migrate --noinput --settings={0}".format(
        _localsettings()
    ), pty=True)


def _localsettings():
    settings = os.getenv('DJANGO_SETTINGS_MODULE', 'base.settings')
    return settings

@task
def fixtures(ctx):
    print "**************************fixtures********************************"


    for fixture in FIXTURES:
        ctx.run("g3w-admin/manage.py loaddata {1} --settings={0}".format(
            _localsettings(), fixture
        ), pty=True)
    
    ctx.run("g3w-admin/manage.py loaddata {1} --settings={0}".format(
        _localsettings(), '/usr/src/g3w-suite/fixtures/admin01.json'
    ), pty=True)

    ctx.run("g3w-admin/manage.py loaddata {1} --settings={0}".format(
        _localsettings(), '/usr/src/g3w-suite/fixtures/group.json'
    ), pty=True)

    ctx.run("g3w-admin/manage.py loaddata {1} --settings={0}".format(
        _localsettings(), '/usr/src/g3w-suite/fixtures/qdjango.json'
    ), pty=True)

    ctx.run("g3w-admin/manage.py sitetree_resync_apps --settings={0}".format(
        _localsettings()
    ), pty=True)

@task
def collectstatic(ctx):
    print "**************************collectstatic********************************"

    ctx.run("g3w-admin/manage.py collectstatic --noinput --settings={0}".format(
        _localsettings()
    ), pty=True)