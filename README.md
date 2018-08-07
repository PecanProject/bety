# BETYdb

[![DOI](https://zenodo.org/badge/4469/PecanProject/bety.svg)](https://zenodo.org/badge/latestdoi/4469/PecanProject/bety)

[![Build Status](https://travis-ci.org/PecanProject/bety.svg?branch=master)](https://travis-ci.org/PecanProject/bety)

[![Slack](https://img.shields.io/badge/slack-login-brightgreen.svg)](https://pecanproject.slack.com/) 
[![Slack](https://img.shields.io/badge/slack-join_chat-brightgreen.svg)](https://publicslack.com/slacks/pecanproject/invites/new) 

This is the source code for the [Biofuel Ecophysiological Traits and Yields database (BETYdb)](http://www.betydb.org)

The website is primarily written in Ruby-on-Rails, and has a PostgreSQL backend.
BETYdb provides an interface for contributing and accessing data, and is the informatics backend for the [Predictive Ecosystem Analyzer (PEcAn)](http://www.pecanproject.org).

## Running BETY using Docker

To get started with BETY you can use the docker-compose.yml file included. This will start the database (postgresql with postgis version 9.5) as well as the BETY container. If this is the first time you start it you will need to initialize the database, this can be done using the following commands:

```
docker-compose -p bety up -d postgres
docker run --rm --network bety_bety pecan/bety initialize
```

Once bety finishes inializing the database, or to restart BETY, you can bring up the all the containers using:

```
docker-compose -p bety up -d
```

To change the path BETY runs under you can change the path using the environment variable RAILS_RELATIVE_URL_ROOT, for example to just run bety you can use the following command. This will precompile any of the static assets and run BETY.

```
docker run -e RAILS_RELATIVE_URL_ROOT="/bety" pecan/bety
```

## Documentation.

* Technical Documentation: https://pecan.gitbooks.io/betydb-documentation/content/
* Data Entry: https://pecan.gitbooks.io/betydbdoc-dataentry/content/
* Data Access: https://pecan.gitbooks.io/betydb-data-access/content/
 
