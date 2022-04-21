# Readme.md

## Purpose

- Demonstrate building a Docker container in stages. Should speed up the
deployment pipeline for new application code considerably.

- Demonstrate build and install of Django 4 w/ Python 3.9 in Docker.

- Demonstrate build and install of Backend Django Python dependencies.

- Deploy an example Django application in a Docker container using gunicorn to launch.

- Example application is front ended by an NGINX reverse proxy. So the flow is as follows:  Web Client <==> NGINX Port 8080 <==> gnuicorn socket <==> Django.

## Contents

- requirements-stage{1-3}.txt: Python "pip" packages.

- xkcd_app/ Directory containing a sample Django application.

- python-unsplash-1.1.0/ Directory containing a hacked version of the
  python-unsplash module. This module is no longer maintained. After manually
relaxing the dependencies it seems to compile and install OK.

- test-imports.py Python code that imports all the modules used by the existing
  backend. If this runs without error then the modules are installed.

## Other Notes

- The majority of Python modules are installed in a Python "venv" virtual
  environment. To activate the virtual environment say "source
 /django/.venv/bin/activate"
