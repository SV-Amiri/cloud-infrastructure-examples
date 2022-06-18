# Amazon Linux required for full compatibility with AWS Fargate
FROM amazonlinux:2022 AS stage1
LABEL Maintainer="Edward Irvine <edward.at.mindhive@gmail.com>"
LABEL Description="Amazon Linux w/ Python3.9 & Django 4 & gunicorn & NGINX"
#ENV PYTHONDONTWRITEBYTECODE=1
#ENV PYTHONUNBUFFERED=1

##
## FIRST: Install basics
##
WORKDIR /tmp
RUN dnf -y update && \
    dnf -y install \
    findutils \
    git \
    lsof \
    procps \
    python-lxml \
    python-pillow \
    python-pip \
    python-psycopg2 \
    python-ruamel-yaml-clib \
    python3-wheel \
    tar \
    telnet && \
    dnf -y autoremove && \
    dnf clean all
# Clean at the end of each stage to reduce image size

##
## SECOND: Install the larger and more complex pip packages.
## These take a bit of time.
##
FROM stage1 AS stage2
WORKDIR /tmp
COPY requirements-stage2.txt .
RUN python3 -m pip install -r requirements-stage2.txt && \
  pip cache purge && \
  dnf -y autoremove && \
  dnf -y clean all

##
## THIRD: Run the app - a basic Django app for testing & demonstation.
##
FROM stage2 AS stage3
WORKDIR /django
COPY . /django/
LABEL ports="8080"
LABEL organisation="example.org"
EXPOSE 8080:8080
STOPSIGNAL SIGQUIT
CMD /django/entrypoint.sh -migrate && \
  /django/entrypoint.sh -run


