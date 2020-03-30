# Change Log
All notable changes are kept in this file. All changes made should be added to the section called
`Unreleased`. Once a new release is made this file will be updated to create a new `Unreleased`
section for the next release.

For more information about this file see also [Keep a Changelog](http://keepachangelog.com/) .

## [Unreleased]

### Fixes
- update doi links http://dx.doi.org --> https://doi.org
- #672 : Added activemodel-serializers-xml Gem to restore functionality of "original" API XML endpoints.
- #674 : Upgraded comma Gem to restore CSV file downloads.

### Added
- dockerfile to dump database in docker image for faster restore of database.

## [5.2.2] - 2019-12-06

This is a minor release and does not require and database updates

### Changed
- updated zenodo.json file to have a successful build and doi generated at zenodo
- updated loofah and rubyzip gem to fix security issues

## [5.2.1] - 2019-08-07

Currently the tested and recommended version of Ruby to be used with BETY is 2.3. BETY compiles and passes tests with 2.4, 2.5 and 2.6 but have not been tested thoroughly with these versions.

### Added

- #643 : Moved `reindex.bety.sh` and `vacuum.bety.sh` scripts from PEcAn to BETY and provided access through entrypoint. 

### Changed

- Documentation updates, now point to new [documentation location](https://pecanproject.github.io/bety-documentation/index.html)
- #652 : Better list of soil choices
- Ruby 2.3.8 is now default ruby when using RVM.

### Fixed

- Updated GEM list to fix security fixes as recommended by dependbot on GitHub.
- Restores method assignment in Bulk Uploads
- Fixed travis build, testing with 2.2, 2.3, 2.4, 2.5 and 2.6 of Ruby.
- Fixed errors when running BETY with 2.4, 2.5 and 2.6
- #668 : show "not found" page for invalid citations.

## [5.2.0] - 2019-03-11

### Added

- Ability to set the initialize URL in docker
- #505 : Added a new attributes table. This table allows to store through polymorphism any additional information with any row in any table. The value stored is a json document.
- #597 : Moved `dump.bety.sh` and `load.bety.sh` from PEcAn to BETY.

## [5.1.0] - 2019-01-14

### Fixed

- #611 : could not close alerts
- #585 : Pressing "Show" on the Covariates Edit page attempts an update
- #621 : A fix for a critical vulnerability reported by Danny Rosseau at Carve Systems (www.carvesystems.com).
- #596 : Crop Model Maps links are broken
- #605 : Allow for keyless API access (using guestuser access)
- #618 : Can not download results of search as csv

## [5.0.5] - 2018-10-23

### Fixed

- #603 : Restores Rails route to make method completion work in Bulk Upload Wizard

## [5.0.4] - 2018-10-11

### Fixed

- #600 : Error when starting BETY as docker container due to frozen variable.

## [5.0.3] - 2018-09-28

### Fixed

- #593 : Replaces references to gitter with references to slack.
- #598 : Fixed issue in docker where the entrypoint referenced a wrong URL to download the initial schema from.

## [5.0.2] - 2018-08-09

### Fixed
- Update to sprockets gem

## [5.0.1] - 2018-08-08

### Fixed
- Fixed fuzzy matching used in search queries

## [5.0.0] - 2018-08-07

### Fixed
- Major upgrade to rails 5, make sure to read documentation on how to upgrade.
