#!/bin/bash

# entrypoint.sh - run by the "CMD" directive in Dockerfile.
# This launches Django (via gunicorn) and NGINX after the container launches.

# turn on bash's job control
set -m

Django=/django
Appdir=${Django}/xkcd_app
# Adjust this. gunicorn recommends setting workers=(2n + 1), where "n" is cores.
Workers=5
Sockfile=${Django}/run/gunicorn.sock

# Create run directory for socket if it doesn't exist
Rundir=$(dirname $Sockfile)
test -d $Rundir || mkdir -p $Rundir

# Start gunicorn/Django and put in background

cd $Appdir
source /${Django}/.venv/bin/activate
pip install xkcd

## <handle static files>
## Warning: Likely you will wish to turn off collectstatic if using
## an external data store like S3.
# Attempt to serve static files directly from nginx
for D in ${Django}/{static,media}
do
  test -d D || mkdir -p $d
done
python3 manage.py collectstatic --noinput # Needed if container rebooted
## </handle static files>
python3 manage.py makemigrations
python3 manage.py migrate
# Unclear if compiling to pyc helps...
python -m compileall .
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
