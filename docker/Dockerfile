# 1.0.13 is the latest version containing bundler 2
FROM phusion/passenger-ruby25:1.0.13

LABEL maintainer="Mapotempo <tech@mapotempo.com>"

ADD . /srv/app
WORKDIR /srv/app

# Install app
ENV RAILS_ENV production
ENV REDIS_HOST redis-cache

RUN apt-get update && \
  apt-get install -y git build-essential zlib1g-dev gdal-bin \
          zlib1g libsqlite3-mod-spatialite libsqlite3-dev \
          libspatialite-dev libnginx-mod-http-headers-more-filter && \
  gem install bundler --version 2 && \
  bundle check || bundle install --full-index --without test development -j $(nproc)

# Cleanup Debian packages
RUN apt-get remove -y git build-essential zlib1g-dev gdal-bin \
            libsqlite3-dev libspatialite-dev && \
  apt-get autoremove -y && \
  apt-get clean && \
  echo -n > /var/lib/apt/extended_states && \
  rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

# Enable Nginx and Passenger
RUN rm -f /etc/service/nginx/down

# Enable app
RUN rm /etc/nginx/sites-enabled/default
ADD docker/env.d/* /etc/nginx/main.d/
ADD docker/webapp.conf /etc/nginx/sites-enabled/

VOLUME /srv/app/poly
