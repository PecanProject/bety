FROM ruby:2.1
MAINTAINER Max Burnette <mburnet2@illinois.edu>

EXPOSE 3000

# Install dependencies
RUN apt-get update &&\
    apt-get install -y sudo curl unzip postgresql-client &&\
    /bin/mkdir /home/bety
    # Create postgres user (which will play nice with postgres container)
    #useradd -s /bin/bash postgres &&\
    #sudo gpasswd -a postgres sudo &&\
    #/bin/chown -R postgres /home/bety &&\
    #/bin/chown postgres /tmp


# Move the bety files out to remote server
COPY / /home/bety/

# Download BETY zip file from pecan archive
RUN cd home/bety &&\
    /bin/cp docker/database.yml config/database.yml &&\
    # Comment out capybara-webkit line and install Rails dependencies
    /bin/sed -i "/capybara-webkit/ s/^/# /" Gemfile &&\
    gem install bundler &&\
    bundle install

# Change permissions for files/folders & change to user postgres
#USER postgres

ENTRYPOINT ["/home/bety/docker/entrypoint.sh"]
CMD ["bety"]
