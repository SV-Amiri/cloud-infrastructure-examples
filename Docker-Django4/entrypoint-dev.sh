#!/bin/bash

# entrypoint-dev.sh - alternative script to run using "CMD" directive in Dockerfile.
# Launches Django after the container launches. No gunicorn, no NGINX.


##
## Setup
##

# Explicitly turn on bash's job control as script is non-interactive.
set -m
# do safe scripting; exit on any failure
set -euo pipefail

##
## Django
##

Django=/django
Appdir=${Django}/xkcd_app
# Adjust workers. Gunicorn recommends setting workers=(2n + 1), where "n" is
# cores. Assumed 2 cores hence w=(2*2+)=5
Workers=5
Sockfile=${Django}/run/gunicorn.sock

# Directory for gunicorn's socket (NGINX connects to the socket).
Rundir=$(dirname $Sockfile)
test -d $Rundir || mkdir -p $Rundir

cd $Appdir
source ${Django}/.venv/bin/activate
## *not used in dev* # <static files>
## *not used in dev* # Warning: Likely you will wish to turn off collectstatic if using
## *not used in dev* # an external data store like S3.
## *not used in dev* # Place static files in a local directory for serving via nginx.
## *not used in dev* for D in ${Django}/{static,media}
## *not used in dev* do
## *not used in dev*   test -d ${D} || mkdir -p ${D}
## *not used in dev* done
## *not used in dev* python3 manage.py collectstatic --noinput # --noinput req'd if
## *not used in dev*                                           # container rebooted
## *not used in dev* # </handle static files>

# Demo app needs the xkcd module
pip install xkcd
python3 manage.py makemigrations
python3 manage.py migrate
# Unclear if compiling to pyc helps...
python -m compileall .
# Launch Django development server.
python3 manage.py runserver 0.0.0.0:8080
## *not used in dev* exec gunicorn xkcd_app.wsgi:application \
## *not used in dev*     --name=xkcd_app \
## *not used in dev*     --workers=${Workers} \
## *not used in dev*     --bind=unix:${Sockfile} \
## *not used in dev*     --log-level=warn \
## *not used in dev*     --log-file=- &
##* not used in dev* # Give gunicorn/django a few seconds to settle.
##* not used in dev* sleep 2
##* not used in dev* 
##* not used in dev* ##
##* not used in dev* ## The NGINX part
##* not used in dev* ##
##* not used in dev* 
##* not used in dev* # Start nginx.
##* not used in dev* echo "Starting nginx"
##* not used in dev* nginx -c /django/nginx.conf -g 'daemon off;'
##* not used in dev* 
##* not used in dev* # bring primary process into foreground and leave there
##* not used in dev* fg %1

