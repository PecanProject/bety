FROM ruby:2.6
LABEL maintainer="Max Burnette <mburnet2@illinois.edu>, Rob Kooper <kooper@illinois.edu>"

# arguments that are added at the bottom of BETY
ARG BETY_GIT_TAGS="unknown"
ARG BETY_GIT_BRANCH="unknown"
ARG BETY_GIT_CHECKSUM="unknown"
ARG BETY_GIT_DATE="unknown"

# environment variables used
ENV LOCAL_SERVER=99 \
    REMOTE_SERVERS="0 1 2 5" \
    INITIALIZE_FLAGS="-g -u" \
    INITIALIZE_URL="-w https://ebi-forecast.igb.illinois.edu/pecan/dump/all/bety.tar.gz" \
    RAILS_ENV="production" \
    RAILS_RELATIVE_URL_ROOT="" \
    SECRET_KEY_BASE="thisisnotasecret" \
    UNICORN_WORKER_PROCESSES="3" \
    UNICORN_PORT="8000" \
    BETY_GIT_TAGS=${BETY_GIT_TAGS} \
    BETY_GIT_BRANCH=${BETY_GIT_BRANCH} \
    BETY_GIT_CHECKSUM=${BETY_GIT_CHECKSUM} \
    BETY_GIT_DATE=${BETY_GIT_DATE} \
    PGHOST=postgres \
    PGUSER=postgres \
    PGDATABASE=postgres \
    BETYUSER=bety \
    BETYPASSWORD=bety \
    BETYDATABASE=bety

# Install dependencies
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        curl \
        git \
        libgeos-dev \
        netcat \
        nodejs \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/* \
    && useradd -m -u 1000 -s /bin/bash bety

# change to working directory
USER bety
WORKDIR /home/bety

# install gems (allowing for caching)
COPY --chown=bety /Gemfile* /home/bety/
RUN gem install bundler -v 1.17.3 \
    && bundle config path vendor/bundle \
    && bundle config without 'test development production debug javascript_testing' \
    && bundle config with 'docker' \
    && bundle install --jobs 4 --retry 3

# copy rest of the files
COPY --chown=bety / /home/bety
COPY --chown=bety /docker/database.yml /home/bety/config/database.yml
COPY --chown=bety /docker/config.ru /home/bety/config.ru

# configure app
RUN /bin/sed -e '/serve_static_assets/ s/false$/true/' -i config/environments/production.rb

# expose public files
VOLUME ["/home/bety/log"]

# port that is exposed
EXPOSE 8000

# default command to run bety web-app
ENTRYPOINT ["/home/bety/docker/entrypoint.sh"]
CMD ["unicorn"]
