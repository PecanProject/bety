FROM alpine

ENV PGHOST=postgres \
    PGPORT=5432 \
    PGDATABASE=postgres \
    PGUSER=postgres \
    PGPASSWORD=postgres \
    BETYUSER=bety \
    BETYPASSWORD=bety \
    BETYDATABASE=bety

RUN apk --no-cache add postgresql

ADD initdb.sh db.dump* /

RUN if [ ! -e /db.dump ]; then pg_dump -F c ${PGDATABASE} > /db.dump; fi

CMD /initdb.sh
