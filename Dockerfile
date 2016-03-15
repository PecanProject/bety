FROM ruby:2.1
MAINTAINER Max Burnette <mburnet2@illinois.edu>

EXPOSE 3000


# Install dependencies
RUN apt-get update &&\
    apt-get install -y sudo curl unzip postgresql-client &&\
    /bin/mkdir /home/bety

COPY / /home/bety

RUN useradd -s /bin/bash postgres &&\
    /bin/chown -R postgres /home/bety

# Create postgres user (which will play nice with postgres container)

# Move the build file & bety config out to remote server
# COPY docker/entrypoint.sh /home/bety/
# COPY docker/database.yml /home/bety/

RUN cd /home/bety &&\
    /bin/sed -i "/capybara-webkit/ s/^/# /" Gemfile &&\
    gem install bundler &&\
    bundle install

# Change permissions for files/folders & change to user postgres
USER postgres

ENTRYPOINT ["/home/bety/docker/entrypoint.sh"]
CMD ["bety"]