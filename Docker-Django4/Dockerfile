##
## Amazon Linux w/ Python 3.9 and Django 4.
##
## Note: Build done in stages so to minimise application deploy time.
##

# Use Amazon Linux version as is compatible with AWS Fargate
FROM amazonlinux:2022 AS stage1
LABEL Maintainer="Edward Irvine <edward.at.mindhive@gmail.com>"
LABEL Description="Amazon Linux w/ Python3.9 & Django 4" 
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1


##
## FIRST: Install the basics
##
RUN dnf -y update && \
  dnf -y group install "Development Tools" && \
  dnf -y install \
    git \
    lsof \
    nginx \
    procps \
    python-devel \
    supervisord \
    telnet
RUN dnf -y install \
  python-lxml \
  python-pillow \
  python-pip \
  python-psycopg2 \
  python-ruamel-yaml-clib \
  python-toml

##
## SECOND: Install the "easy", lightweight pip packages
##
FROM stage1 AS stage2
WORKDIR /django
COPY requirements-stage2.txt /django
RUN python3 -m venv .venv && \
  source .venv/bin/activate && \
  python3 -m pip install --upgrade pip && \
  pip install -r requirements-stage2.txt
# Hackage: python-unsplash module unmaintained and won't install.  I've
# modified the source in local version below to relax dependencies. Seems to
# work.
RUN mkdir python-unsplash-1.1.0
COPY ./python-unsplash-1.1.0/ python-unsplash-1.1.0/
RUN source .venv/bin/activate && \
  cd ./python-unsplash-1.1.0 && \
  python3 setup.py install clean

##
## THIRD: Install the larger and more complex pip packages.
## These take a bit of time.
##
FROM stage2 AS stage3
WORKDIR /django
COPY requirements-stage3.txt .
RUN source .venv/bin/activate && \
  pip install -r requirements-stage3.txt

##
## FOURTH: Cleanup install
##
FROM stage3 AS stage4
RUN dnf -y group remove "Development Tools" && \
  dnf -y remove python3-devel && \
  dnf -y autoremove && \
  dnf -y clean all
WORKDIR /django
RUN source .venv/bin/activate && \
  pip cache purge

##
## FIFTH: Run the xkcd_app - a basic Django app for testing
##
FROM stage4 AS stage5
WORKDIR /django
COPY . /django/
LABEL ports="8000"
LABEL organisation="mindhive.org"
EXPOSE 8000:8000
WORKDIR /django/xkcd_app
# Installs the "xkcd" module needed by the example Django app, set up
# database, then use the "gunicorn" tool to serve Django content.
#
# gunicorn recommend the number of workers to be w=(2n +1), where "n" is
# the number of CPU cores. Below I'm assuming we have 2 cores, so thus we 
# launch w=5 workers
CMD source /django/.venv/bin/activate && \
  pip install xkcd && \
  python3 manage.py migrate && \
  exec gunicorn -w5 xkcd_app.wsgi:application --bind 0.0.0.0:8000
