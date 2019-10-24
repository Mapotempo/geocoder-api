FROM ruby:2.3-slim as rake

ENV LANG C.UTF-8

COPY . /srv/app
WORKDIR /srv/app
# Install app
RUN apt-get update > /dev/null && \
  apt install -y git build-essential zlib1g-dev gdal-bin \
    zlib1g libsqlite3-mod-spatialite libsqlite3-dev \
    libspatialite-dev

RUN bundle check --path vendor/bundle || bundle install --full-index --without development --path vendor/bundle

# Final image
FROM ruby:2.3-slim

ENV LANG C.UTF-8
ENV RAILS_ENV production
ENV REDIS_HOST redis-cache

LABEL maintainer="Mapotempo <tech@mapotempo.com>"

VOLUME /srv/app/poly

COPY --from=rake /srv/app /srv/app
COPY --from=rake /usr/local/ /usr/local/
COPY --from=rake /usr/lib/x86_64-linux-gnu/ /usr/lib/x86_64-linux-gnu/

WORKDIR /srv/app
EXPOSE 8558

CMD ["bundle", "exec", "rake", "server"]