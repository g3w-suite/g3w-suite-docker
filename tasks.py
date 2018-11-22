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

def _dbsettings():
    return {
        'name': os.getenv('G3WSUITE_DATABASE_NAME'),
        'user': os.getenv('G3WSUITE_DATABASE_USER'),
        'password': os.getenv('G3WSUITE_DATABASE_PASSWORD'),
    }

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

@task
def movegeodata(ctx):
    print "**************************movegeodata********************************"



    ctx.run("mv geodata/* /djangoassets/geodata/", pty=True)

@task
def restoredump(ctx):
    print "**************************restoredump********************************"

    settings = _dbsettings()
    db_connetcion = "PGPASSWORD={0} psql -h db -U {1}  -d {2}".format(
        settings['password'],
        settings['user'],
        settings['name']
    )

    # create database geodata dump for postgis project
    ctx.run("{} -c \"CREATE DATABASE geodata template=template_postgis\"".format(db_connetcion), pty=True)


    # restore dump data
    ctx.run("PGPASSWORD={0} pg_restore -h db -U {1} -d geodata -O -x {2}".format(
        settings['password'],
        settings['user'],
        '/djangoassets/geodata/geodata.backup'
    ), pty=True)

