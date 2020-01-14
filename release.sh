#!/bin/bash

VERSION="5.2.0"
#DEBUG=echo

TAGS=""
TMPVERSION="${VERSION}"
OLDVERSION=""
while [ "$OLDVERSION" != "$TMPVERSION" ]; do
    TAGS="${TAGS} ${TMPVERSION}"
    OLDVERSION="${TMPVERSION}"
    TMPVERSION=$(echo ${OLDVERSION} | sed 's/\.[0-9]*$//')
done

${DEBUG} docker pull pecan/bety:${VERSION}

for x in ${TAGS}; do
  if [ "$x" == "$VERSION" ]; then continue; fi

  ${DEBUG} docker tag pecan/bety:${VERSION} pecan/bety:$x
  ${DEBUG} docker push pecan/bety:$x
done
