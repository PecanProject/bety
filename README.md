# BETYdb

[![DOI](https://zenodo.org/badge/4469/PecanProject/bety.svg)](https://zenodo.org/badge/latestdoi/4469/PecanProject/bety)

[![Build Status](https://github.com/PecanProject/bety/workflows/CI/badge.svg)](https://github.com/PecanProject/bety/actions?query=workflow%3ACI)

[![Slack](https://img.shields.io/badge/slack-login-brightgreen.svg)](https://pecanproject.slack.com/) 
[![Slack](https://img.shields.io/badge/slack-join_chat-brightgreen.svg)](https://publicslack.com/slacks/pecanproject/invites/new) 

This is the source code for the [Biofuel Ecophysiological Traits and Yields database (BETYdb)](http://www.betydb.org)

The website is primarily written in Ruby-on-Rails, and has a PostgreSQL backend.
BETYdb provides an interface for contributing and accessing data, and is the informatics backend for the [Predictive Ecosystem Analyzer (PEcAn)](http://www.pecanproject.org).

## Running BETY using Docker

To get started with BETY you can use the docker-compose.yml file included. This will start the database (postgresql with postgis version 9.5) as well as the BETY container. If this is the first time you start it you will need to initialize the database, this can be done using the following commands:

```
docker-compose -p bety up -d postgres
docker run --rm --network bety_bety pecan/db
```

If you want to change the id of the database, you can use:

```
docker-compose run -e LOCAL_SERVER=77 bety fix
```

To add initial users you can use the following commands (this will add the guestuser as well as the carya demo user)

```
docker-compose run bety user 'guestuser' 'guestuser' 'Guest User' 'betydb@gmail.com' 1 1"
docker-compose run bety user 'carya' 'illinois' 'Demo User' 'betydb@gmail.com' 1 1"
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

* Technical Documentation: https://pecanproject.github.io/bety-documentation/technical/
* Data Entry: https://pecanproject.github.io/bety-documentation/dataentry/
* Data Access: https://pecan.gitbook.io/betydb-data-access/
 
