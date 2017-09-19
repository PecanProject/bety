FROM ruby:2.1
MAINTAINER Max Burnette <mburnet2@illinois.edu>

# port that is exposed (standard ruby port)
EXPOSE 3000

# environment variables used
ENV LOCAL_SERVER=99 \
    REMOTE_SERVERS="0 1 2 5" \
    RAILS_ENV="production" 

# Install dependencies
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        curl \
        git \
        netcat \
        postgresql-client \
    && rm -rf /var/lib/apt/lists/*

# change to working directory
WORKDIR /home/bety

# install gems (allowing for caching)
COPY /Gemfile* /home/bety/
RUN gem install bundler && \
    bundle install --without javascript_testing --path vendor/bundle

# copy rest of the files
COPY / /home/bety

# download dump.bety and load.bety scripts
RUN curl -LOs https://raw.githubusercontent.com/PecanProject/pecan/master/scripts/load.bety.sh && \
    curl -LOs https://raw.githubusercontent.com/PecanProject/pecan/master/scripts/dump.bety.sh && \
    chmod +x load.bety.sh dump.bety.sh

ENTRYPOINT ["/home/bety/docker/entrypoint.sh"]
CMD ["server"]
