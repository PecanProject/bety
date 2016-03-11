FROM ruby:2.1
MAINTAINER Max Burnette <mburnet2@illinois.edu>

EXPOSE 3000

# Install dependencies
RUN apt-get update &&\
    apt-get install -y sudo curl unzip postgresql-client &&\
    /bin/mkdir /home/bety &&\
    useradd -s /bin/bash postgres &&\
    #echo "postgres:postgres" | chpasswd &&\
    #adduser postgres sudo &&\
    /bin/chown -R postgres /home/bety

# Create postgres user (which will play nice with postgres container)

# Move the build file & bety config out to remote server
COPY entrypoint.sh /home/bety/
COPY database.yml /home/bety/

# Change permissions for files/folders & change to user postgres
# RUN chown -R postgres /home/bety
USER postgres

ENTRYPOINT ["/home/bety/entrypoint.sh"]
CMD ["bety"]


