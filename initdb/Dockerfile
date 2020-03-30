# syntax = docker/dockerfile:experimental
FROM alpine

RUN apk --no-cache add postgresql \
    && pg_dump -h postgres -U postgres -F c bety > /betydb.dump
COPY initdb.sh /

CMD /initdb.sh
