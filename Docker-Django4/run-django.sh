#!/usr/bin/env bash
# Example of you you can launch the xkcd_app manually.
set -e
source /django/.venv/bin/activate
cd /django/xkcd_app
exec gunicorn -w4 xkcd_app.wsgi:application --bind 0.0.0.0:8080

