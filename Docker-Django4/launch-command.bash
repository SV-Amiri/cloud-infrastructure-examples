#!/bin/bash

# launch-command.bash - run by the "CMD" directive in Dockerfile.
# This launches Django (via gunicorn) and NGINX after the container launches.

# turn on bash's job control
set -m

Django=/django
Appdir=${Django}/xkcd_app
Workers=5
Sockfile=${Django}/run/gunicorn.sock

# Create the run directory if it doesn't exist
Rundir=$(dirname $Sockfile)
test -d $Rundir || mkdir -p $Rundir

# Start gunicorn/Django and put in background

cd $Appdir
source /${Django}/.venv/bin/activate
pip install xkcd
# Attempt to serve static files directly from nginx
mkdir -p ${Django}/{static,media} 2>/dev/null
python3 manage.py collectstatic
python3 manage.py migrate
exec gunicorn xkcd_app.wsgi:application \
    --name=xkcd_app \
    --workers=${Workers} \
    --bind=unix:${Sockfile} \
    --log-level=warn \
    --log-file=- &

# Wait for gunicorn/django to start before launching NGINX
sleep 2

# Start nginx
echo "Starting nginx"
nginx -c /django/nginx.conf -g 'daemon off;'

# the my_helper_process might need to know how to wait on the
# primary process to start before it does its work and returns


# now we bring the primary process back into the foreground
# and leave it there
fg %1
