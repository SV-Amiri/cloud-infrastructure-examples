#!/bin/bash

# launch-command.bash - run by the "CMD" directive in Dockerfile.
# This launches Django (via gunicorn) and NGINX after the container launches.

# turn on bash's job control
set -m

Django=/django
Appdir=${Django}/xkcd_app
# Adjust this. gunicorn recommends setting workers=(2n + 1), where "n" is cores.
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
python3 manage.py collectstatic --noinput # Needed if container rebooted
python3 manage.py makemigrations
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

# now we bring the primary process back into the foreground
# and leave it there
fg %1
