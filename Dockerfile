FROM ruby:2.1
MAINTAINER Max Burnette <mburnet2@illinois.edu>

EXPOSE 3000

# Install dependencies
RUN apt-get update &&\
    apt-get install -y sudo curl netcat &&\
    /bin/mkdir /home/bety

# Install postgres client from officially versioned repos
RUN sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main" > /etc/apt/sources.list.d/pgdg.list' &&\
    apt-get install wget ca-certificates &&\
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add - &&\
    apt-get -y update &&\
    apt-get -y upgrade &&\
    apt-get install -y postgresql-client-9.4

COPY / /home/bety

RUN cd /home/bety &&\
    gem install bundler &&\
    bundle install --without javascript_testing

ENTRYPOINT ["/home/bety/docker/entrypoint.sh"]
CMD ["bety"]
