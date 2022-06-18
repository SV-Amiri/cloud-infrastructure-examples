#!/bin/bash

# entrypoint.sh - run by the "CMD" directive in Dockerfile.
# Launches Django (via gunicorn) and NGINX after the container launches.

# Optional arguments (one only):
#   -collectstatic
#   -help
#   -makemigrations
#   -migrate
#   -run (default)


##
## Safety
##

# Explicitly turn on bash's job control script to non-interactive.
set -m
# Safe scripting; exit on any failure
set -euo pipefail

##
## Environment Variables
##

# $DJANGO_ROOT should also be defined in the Dockerfile.
Django_Root=${DJANGO_ROOT:=/django}
Django_Project="mysite"
Django_Project_Root=${Django_Root}/${Django_Project}

##
## Parse command line
##

showUsage()
{
    echo "Usage: entrypoint.sh [ -help | -collectstatic | -makemigrations | -migrate | -run ] "
    echo "  without arguments \"-run\" is assumed."
    exit 2
}

# Returns the count of arguments that are in short or long options
NumArgs=$#

if [[ $NumArgs -gt 1 ]]
then
  showUsage
elif [[ $NumArgs -eq 0 ]]
then
  DjangoManageCmd="run"
else
  case "$1" in
    -collectstatic)
      DjangoManageCmd="collectstatic --noinput"
      ;;
    -help)
      showUsage
      ;;
    -makemigrations)
      DjangoManageCmd="makemigrations"
      ;;
    -migrate)
      DjangoManageCmd="migrate"
      ;;
    -run)
      DjangoManageCmd="run"
      ;;
    *)
      echo "Unexpected option: $1"
      help
      ;;
  esac
fi

##
## Setup Django
##

Appdir=${Django_Root}/xkcd_app
# Adjust workers. Gunicorn recommends setting workers=(2n + 1), where "n" is
# cores. Assumed 4 cores hence w=(2*4+1)=9
Workers=9
Sockfile=/tmp/run/gunicorn.sock

# Directory for gunicorn's socket (NGINX connects to the socket).
Rundir=$(dirname $Sockfile)
test -d $Rundir || mkdir -p $Rundir

cd ${Django_Project_Root}

# If we have been told to collectstatic, makemigrations, or migrate,
# we do that and then exit without launching the app.

case "$DjangoManageCmd" in
  collectstatic)
    # Warning: Likely you will wish to turn off collectstatic if using
    # an external data store like S3.
    # Place static files in a local directory for serving via nginx.
    for D in ${Django}/{static,media}
    do
      test -d ${D} || mkdir -p ${D}
    done
    python3 manage.py collectstatic --noinput
    echo "Collected static files. Bye!"
    exit 0
    ;;
  makemigrations)
    python3 manage.py makemigrations
    echo "Ran makemigrations Bye!"
    exit 0
    ;;
  migrate)
    python3 manage.py migrate
    echo "Ran migrate. Bye!"
    exit 0
    ;;
  *)
    ;;
esac

# If we get here we must want to launch the app. Fingers crossed!

# Unclear if compiling to pyc helps...
python3 -m compileall .
#python3 manage.py collectstatic --noinput
#python3 manage.py makemigrations
#python3 manage.py migrate
# Launch gunicorn/Django in background
exec gunicorn ${Django_Project}.wsgi:application \
    --name=${Django_Project} \
    --workers=${Workers} \
    --bind=0.0.0.0:8080 \
    --log-level=warn \
    --log-file=- &

# To bind to a socket say "--bind=unix:${Sockfile}"

# Give gunicorn/django a few seconds to settle.
sleep 2


#<development without nginx>
# if you wanted to dispense with nginxand instead have gunicorn
# serve directly on (say) port 8080, modify the above block like so:
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
#      --bind=0.0.0.0:8080 \
#      --log-level=warn \
#      --log-file=- &
#
#  Then comment out the part below that launches nginx.
#
#</development without nginx>


##
## The NGINX part
##

# Start nginx.
#echo "Starting nginx"
#nginx -c ${DJANGO_ROOT}/nginx.conf -g 'daemon off;'

# bring primary process into foreground and leave there
fg %1

