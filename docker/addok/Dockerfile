FROM python:3.4

LABEL maintainer="Mapotempo <contact@mapotempo.com>"

ARG ADDOK_VERSION
ENV ADDOK_VERSION ${ADDOK_VERSION:-1.1.0-rc1}
ENV ADDOK_FR_VERSION 1.0.1
ENV ADDOK_FRANCE_VERSION 1.1.0
ENV ADDOK_LUXEMBURG_VERSION 1.2.0
ENV ADDOK_CSV_VERSION 1.0.1
ENV ADDOK_FRANCE_CLEAN_VERSION 1.0.0
ENV ADDOK_LUXEMBURG_CLEAN_VERSION 1.2.0
ENV ADDOK_SEARCH_2_STEPS_VERSION 1.1.0-2
ENV ADDOK_USAGE_NAME_BAN_FR_VERSION 1.0.0
ENV ADDOK_USAGE_NAME_LU_VERSION 1.1.0
ENV ADDOK_SCORE_PREPROCESSSED_QUERY_VERSION 1.0.0

RUN apt-get -q update && \
    apt-get -qy install redis-tools jq && \
    \
    pip install gunicorn addok==${ADDOK_VERSION} addok-fr==${ADDOK_FR_VERSION} addok-france==${ADDOK_FRANCE_VERSION} addok-csv==${ADDOK_CSV_VERSION} && \
    pip install git+https://github.com/frodrigo/addok_luxemburg@v${ADDOK_LUXEMBURG_VERSION} && \
    pip install git+https://github.com/Mapotempo/addok_france_clean@v${ADDOK_FRANCE_CLEAN_VERSION} && \
    pip install git+https://github.com/frodrigo/addok_luxemburg_clean@v${ADDOK_LUXEMBURG_CLEAN_VERSION} && \
    pip install git+https://github.com/Mapotempo/addok_search2steps@v${ADDOK_SEARCH_2_STEPS_VERSION} && \
    pip install git+https://github.com/Mapotempo/addok_usage_name_BAN_FR@v${ADDOK_USAGE_NAME_BAN_FR_VERSION} && \
    pip install git+https://github.com/frodrigo/addok_usage_name_LU@v${ADDOK_USAGE_NAME_LU_VERSION} && \
    pip install git+https://github.com/Mapotempo/addok_score_preprocessed_query@v${ADDOK_SCORE_PREPROCESSSED_QUERY_VERSION} && \
    mkdir /etc/addok && \
    \
# Cleanup Debian packages
    apt-get remove -y git build-essential zlib1g-dev gdal-bin && \
    apt-get autoremove -y && \
    apt-get clean && \
    echo -n > /var/lib/apt/extended_states && \
    rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

EXPOSE 7878

ENTRYPOINT ["gunicorn"]

CMD ["--bind", "0.0.0.0:7878", "--timeout", "7200", "--workers", "8", "addok.http.wsgi"]
