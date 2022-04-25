##
## Amazon Linux w/ Python 3.9, Django 4, gunicorn, and NGINX.
##
## Client <==> NGINX <==> gunicorn <==> Django
##
## Staged build to minimise deploy pipeline time.
##

# Inputs:
# ------
# a) ./requirements-stage{1-3}.txt - list of python modules installed by pip
# b) ./entrypoint.sh - bash file. Executes when container starts. Runs the
#    applications.
# c) ./python-unsplash-1.1.0.tar - hacked version of python-unsplash module.
#    Dependencies relaxed so it works on Python 3.9.
# d) ./xkcd_app/ - Example Django application.
# e) ./nginx.conf - nginx configuration file.
#
# Please note that requirements-stage{1-3}.txt almost needs to be modified for
# your own use. Majority of modules are there for my particular project and
# likely can be removed for your project.


# Amazon Linux required for full compatibility with AWS Fargate
FROM amazonlinux:2022 AS stage1
LABEL Maintainer="Edward Irvine <edward.at.mindhive@gmail.com>"
LABEL Description="Amazon Linux w/ Python3.9 & Django 4 & gunicorn & NGINX"
#ENV PYTHONDONTWRITEBYTECODE=1
#ENV PYTHONUNBUFFERED=1

##
## FIRST: Install basics
##
RUN dnf -y update && \
    dnf -y install \
    findutils \
    git \
    lsof \
    nginx \
    procps \
    python-lxml \
    python-pillow \
    python-pip \
    python-psycopg2 \
    python-ruamel-yaml-clib \
    telnet && \
    dnf -y autoremove && \
    dnf clean all
# Clean at the end of each stage to reduce image size

##
## SECOND: Install the larger and more complex pip packages.
## These take a bit of time.
##
FROM stage1 AS stage2
WORKDIR /django
COPY requirements-stage2.txt .
RUN  dnf -y group install "Development Tools" && \
  dnf -y install python-devel && \
  python3 -m venv .venv && \
  source .venv/bin/activate && \
  python3 -m pip install --upgrade pip && \
  pip install -r requirements-stage2.txt && \
  pip cache purge && \
  dnf -y group remove "Development Tools" && \
  dnf -y remove python3-devel && \
  dnf -y autoremove && \
  dnf -y clean all

##
## THIRD: Install remainder of python modules. These are relatively
## lightweight.
##
FROM stage2 AS stage3
WORKDIR /django
COPY ./requirements-stage3.txt .
# Hackage: python-unsplash module unmaintained and won't install.  I've
# modified the source in local version below to relax dependencies. Seems to
# work.
ADD ./python-unsplash-1.1.0.tar .
RUN  dnf -y group install "Development Tools" && \
  dnf -y install python-devel && \
  source .venv/bin/activate && \
  pip install -r requirements-stage3.txt && \
  cd ./python-unsplash-1.1.0 && \
  python3 setup.py install clean && \
  dnf -y group remove "Development Tools" && \
  dnf -y remove python3-devel && \
  dnf -y autoremove && \
  dnf -y clean all && \
  pip cache purge

##
## FOURTH: Add the pre-trained pipeline package for python spacy module
##
FROM stage3 AS stage4
WORKDIR /django
RUN source .venv/bin/activate && \
  python3 -m spacy download en_core_web_md

##
## FIFTH: Run the xkcd_app - a basic Django app for testing & demonstation.
##
FROM stage4 AS stage5
WORKDIR /django
COPY . /django/
LABEL ports="8080"
LABEL organisation="example.org"
EXPOSE 8080:8080
WORKDIR /django/xkcd_app
STOPSIGNAL SIGQUIT
RUN  ln -sf /dev/stdout /var/log/nginx/access.log && \
     ln -sf /dev/stderr /var/log/nginx/error.log
CMD /django/entrypoint.sh

# Note: There's an alternative script /django/entrypoint-dev.sh. This launches
# the Django development server only. No gunicorn. No nginx.

