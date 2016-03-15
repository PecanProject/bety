FROM ruby:2.1
MAINTAINER Max Burnette <mburnet2@illinois.edu>

EXPOSE 3000

# Install dependencies
RUN apt-get update &&\
    apt-get install -y sudo curl unzip netcat postgresql-client &&\
    /bin/mkdir /home/bety

COPY / /home/bety

RUN cd /home/bety &&\
    /bin/sed -i "/capybara-webkit/ s/^/# /" Gemfile &&\
    gem install bundler &&\
    bundle install

ENTRYPOINT ["/home/bety/docker/entrypoint.sh"]
CMD ["bety"]
