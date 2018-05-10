FROM ruby:2.3
MAINTAINER Max Burnette <mburnet2@illinois.edu>

# Install dependencies
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        curl \
        git \
        libgeos-dev \
        netcat \
        nodejs \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# change to working directory
WORKDIR /home/bety

# install gems (allowing for caching)
COPY /Gemfile* /home/bety/
RUN gem install bundler \
    && bundle install --with docker --without "test development production debug javascript_testing"


# port that is exposed (standard ruby port)
EXPOSE 8000

# copy rest of the files
COPY / /home/bety
COPY /docker/database.yml /home/bety/config/database.yml
COPY /docker/config.ru /home/bety/config.ru

# download dump.bety and load.bety scripts and configure app
RUN curl -LOs https://raw.githubusercontent.com/PecanProject/pecan/master/scripts/load.bety.sh \
    && curl -LOs https://raw.githubusercontent.com/PecanProject/pecan/master/scripts/dump.bety.sh \
    && chmod +x load.bety.sh dump.bety.sh \
    && /bin/sed -e '/serve_static_assets/ s/false$/true/' -i config/environments/production.rb

# arguments that are added at the bottom of BETY
ARG BETY_GIT_TAGS="unknown"
ARG BETY_GIT_BRANCH="unknown"
ARG BETY_GIT_CHECKSUM="unknown"
ARG BETY_GIT_DATE="unknown"

# environment variables used
ENV LOCAL_SERVER=99 \
    REMOTE_SERVERS="0 1 2 5" \
    RAILS_ENV="production" \
    RAILS_RELATIVE_URL_ROOT="" \
    SECRET_KEY_BASE="ThisIsNotReallySuchAGreatSecret" \
    UNICORN_WORKER_PROCESSES="3" \
    UNICORN_PORT="8000" \
    BETY_GIT_TAGS=${BETY_GIT_TAGS} \
    BETY_GIT_BRANCH=${BETY_GIT_BRANCH} \
    BETY_GIT_CHECKSUM=${BETY_GIT_CHECKSUM} \
    BETY_GIT_DATE=${BETY_GIT_DATE}

# expose public files
VOLUME ["/home/bety/public"]

# default command to run bety web-app
ENTRYPOINT ["/home/bety/docker/entrypoint.sh"]
CMD ["unicorn"]
