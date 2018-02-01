FROM mapotempo/nginx-passenger:2.0.1

LABEL maintainer="Mapotempo <contact@mapotempo.com>"

ENV RAILS_ENV production
ENV REDIS_HOST redis-cache

ADD . /srv/app

# Install app
RUN apt-get update && \
    apt-get install -y git build-essential zlib1g-dev gdal-bin \
            zlib1g libsqlite3-mod-spatialite libsqlite3-dev \
            libspatialite-dev && \
    cd /srv/app && \
    bundle install --full-index --without test development && \
    \
# Fix permissions
    chown -R www-data:www-data . && \
    \
# Cleanup Debian packages
    apt-get remove -y git build-essential zlib1g-dev gdal-bin \
            libsqlite3-dev libspatialite-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

ADD docker/env.d/* /etc/nginx/env.d/

VOLUME /srv/app/poly

WORKDIR /srv/app
