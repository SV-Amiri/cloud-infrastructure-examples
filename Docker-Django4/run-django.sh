#!/usr/bin/env bash
set -e
source /django/.venv/bin/activate
cd /django/xkcd_app
exec gunicorn -w4 xkcd_app.wsgi:application --bind 0.0.0.0:8000

