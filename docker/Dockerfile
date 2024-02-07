# 1.0.13 is the latest version containing bundler 2
FROM phusion/passenger-ruby27:2.5.1

VOLUME /srv/app/poly

LABEL maintainer="Mapotempo <tech@mapotempo.com>"
ARG BUNDLE_WITHOUT="development test"

ADD . /srv/app
WORKDIR /srv/app

# Install app
ENV REDIS_HOST redis-cache

RUN apt-get update && \
  apt-get install -y git build-essential zlib1g-dev gdal-bin \
          zlib1g libsqlite3-mod-spatialite libsqlite3-dev \
          libspatialite-dev libnginx-mod-http-headers-more-filter && \
  gem install bundler --version 2 && \
  bundle install --path vendor/bundle --full-index --without ${BUNDLE_WITHOUT} -j $(nproc)

USER root

# Enable Nginx and Passenger
RUN rm -f /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default

# Enable app
ADD docker/env.d/* /etc/nginx/main.d/
ADD docker/snippets/* /etc/nginx/snippets/
ADD docker/webapp.conf /etc/nginx/sites-enabled/webapp.conf

# Cleanup Debian packages
RUN apt-get remove -y git build-essential zlib1g-dev gdal-bin \
            libsqlite3-dev libspatialite-dev && \
  apt-get autoremove -y && \
  apt-get clean && \
  echo -n > /var/lib/apt/extended_states && \
  rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*
