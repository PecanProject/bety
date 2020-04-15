# syntax = docker/dockerfile:experimental
FROM alpine

RUN apk --no-cache add postgresql
ADD initdb.sh db.dump* /
RUN if [ ! -e /db.dump ]; then pg_dump -F c ${PGDATABASE} > /db.dump; fi

CMD /initdb.sh
