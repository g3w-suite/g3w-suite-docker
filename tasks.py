import ast
import json
import logging
import os
import re

import docker

from invoke import run, task

BOOTSTRAP_IMAGE_CHEIP = 'codenvy/che-ip:nightly'


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