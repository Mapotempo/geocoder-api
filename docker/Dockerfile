FROM mapotempo/nginx-passenger:latest

LABEL maintainer="Mapotempo <contact@mapotempo.com>"

ENV RAILS_ENV production
ENV REDIS_HOST redis-cache

ADD . /srv/app

# Install app
RUN apt-get update && \
    apt-get install -y git build-essential zlib1g-dev gdal-bin \
            zlib1g && \
    cd /srv/app && \
    bundle install --full-index --without test development && \
    \
# Fix permissions
    chown -R www-data:www-data . && \
    \
# Cleanup Debian packages
    apt-get remove -y git build-essential zlib1g-dev gdal-bin && \
    apt-get autoremove -y && \
    apt-get clean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

VOLUME /srv/app/poly

WORKDIR /srv/app