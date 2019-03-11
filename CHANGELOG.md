# Change Log
All notable changes are kept in this file. All changes made should be added to the section called
`Unreleased`. Once a new release is made this file will be updated to create a new `Unreleased`
section for the next release.

For more information about this file see also [Keep a Changelog](http://keepachangelog.com/) .

## [5.2.0] - 2019-03-11

### Added

- Ability to set the initialize URL in docker
- #505 : Added a new attributes table. This table allows to store through polymorphism any additional information with any row in any table. The value stored is a json document.
- #597 : Moved `dump.bety.sh` and `load.bety.sh` from PEcAn to BETY.

## [5.1.0] - 2019-01-14

### Fixes

- #611 : could not close alerts
- #585 : Pressing "Show" on the Covariates Edit page attempts an update
- #621 : A fix for a critical vulnerability reported by Danny Rosseau at Carve Systems (www.carvesystems.com).
- #596 : Crop Model Maps links are broken
- #605 : Allow for keyless API access (using guestuser access)
- #618 : Can not download results of search as csv

## [5.0.5] - 2018-10-23

### Fixes

- #603 : Restores Rails route to make method completion work in Bulk Upload Wizard

## [5.0.4] - 2018-10-11

### Fixes

- #600 : Error when starting BETY as docker container due to frozen variable.

## [5.0.3] - 2018-09-28

### Fixes

- #593 : Replaces references to gitter with references to slack.
- #598 : Fixes issue in docker where the entrypoint referenced a wrong URL to download the initial schema from.

## [5.0.2] - 2018-08-09

### Fixes
- Update to sprockets gem

## [5.0.1] - 2018-08-08

### Fixes
- Fixes fuzzy matching used in search queries

## [5.0.0] - 2018-08-07

### Fixes
- Major upgrade to rails 5, make sure to read documentation on how to upgrade.
