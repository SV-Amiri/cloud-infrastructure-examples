#!/bin/bash

# entrypoint.sh - run by the "CMD" directive in Dockerfile.
# Launches Django (via gunicorn) and NGINX after the container launches.


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
# <static files>
# Warning: Likely you will wish to turn off collectstatic if using
# an external data store like S3.
# Place static files in a local directory for serving via nginx.
for D in ${Django}/{static,media}
do
  test -d ${D} || mkdir -p ${D}
done
python3 manage.py collectstatic --noinput # --noinput req'd if
                                          # container rebooted
# </handle static files>

# Demo app needs the xkcd module
pip install xkcd
python3 manage.py makemigrations
python3 manage.py migrate
# Unclear if compiling to pyc helps...
python -m compileall .
# Launch gunicorn/Django in background
exec gunicorn xkcd_app.wsgi:application \
    --name=xkcd_app \
    --workers=${Workers} \
    --bind=unix:${Sockfile} \
    --log-level=warn \
    --log-file=- &
# Give gunicorn/django a few seconds to settle.
sleep 2

#<development without nginx>
# if you wanted to dispense with nginxand instead have gunicorn
# serve directly on (say) port 8000, modify the above block like so:
#
#  # python3 manage.py collectstatic <-- don't run "collectstatic"
#  pip install xkcd
#  python3 manage.py makemigrations
#  python3 manage.py migrate
#  python -m compileall .
#  # Launch gunicorn/Django in background, listening on port 8000
#  exec gunicorn xkcd_app.wsgi:application \
#      --name=xkcd_app \
#      --workers=${Workers} \
#      --bind=0.0.0.0:8000 \
#      --log-level=warn \
#      --log-file=- &
#</development without nginx>


##
## The NGINX part
##

# Start nginx.
echo "Starting nginx"
nginx -c /django/nginx.conf -g 'daemon off;'

# bring primary process into foreground and leave there
fg %1

