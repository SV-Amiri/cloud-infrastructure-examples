##
## Amazon Linux w/ Python 3.9, Django 4, gunicorn, and NGINX.
##
## Client <==> NGINX <==> gunicorn <==> Django
##
## Staged build to minimise deploy pipeline time.
##

# Use Amazon Linux for compatibility with AWS Fargate
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
# Clean up at the end of each stage to reduce image size

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
## THIRD: Install the "easy", lightweight pip packages
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
LABEL organisation="mindhive.org"
EXPOSE 8080:8080
WORKDIR /django/xkcd_app
STOPSIGNAL SIGQUIT
RUN  ln -sf /dev/stdout /var/log/nginx/access.log && \
     ln -sf /dev/stderr /var/log/nginx/error.log
CMD /django/entrypoint.sh

##   NB: for development you can luanch gunicorn like so:
##      source /django/.venv/bin/activate && \
##      cd /django/xkcd_app && \
##      exec gunicorn -w5 xkcd_app.wsgi:application --bind 0.0.0.0:8080
