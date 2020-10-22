# Change Log
All notable changes are kept in this file. All changes made should be added to the section called
`Unreleased`. Once a new release is made this file will be updated to create a new `Unreleased`
section for the next release.

For more information about this file see also [Keep a Changelog](http://keepachangelog.com/) .

## Migrations

Some of the changes require a migration. Depending on how you run BETY you can use one of the following options. No matter what, make sure you have a backup of your database before you do the migration, just in case.

### Native Install

You will need to install the latest version of BETY (or the version you want to migrate to), and run `rake db:migrate SKIP_SCHEMASPY=YES`.

### Docker (with docker compose)

In this case you can simply pull down the version you want, and run `docker-compose bety migrate`.

## [Unreleased]

### Added
- configuration to sync forks of BETY using https://github.com/wei/pull

### Fixes
- Fixes to the docker build to fit in kubernetes helm chart.
- Added Wisconsin back to database dump workflow
- Catch exception when load.bety fails and cleans up /tmp folder
- Fix problem with sendmail causing error on new user sign up https://github.com/PecanProject/bety/issues/677

### Changed

- [#705](https://github.com/PecanProject/bety/pull/705) : More clearly indicate method is optional in bulk upload
- updated rails to 5.1.7
- removed static route, it was only used to render 404.
- allow n=1 in bulk upload https://github.com/PecanProject/bety/pull/704


## [5.3.0] - 2020-04-15

### Fixes
- #696 : actually now uses environment variable SECRET_KEY_BASE. If this was set, unset otherwise you can not login to BETY.
- #551 : remove GUnload message from console on page change.
- #672 : Added activemodel-serializers-xml Gem to restore functionality of "original" API XML endpoints.
- #674 : Upgraded comma Gem to restore CSV file downloads.
- use actual information in database for load and dump scripts.
- update doi links http://dx.doi.org --> https://doi.org
- fixed functions to explicitly add public. to function call and table reference. (this will require a migration)
- upgrade rake to 13.0.1 (dependbot fix)
- upgrade nokogiri to 1.10.8 (dependbot fix)

### Added
- script to add new users to bety
- dockerfile to dump database in docker image for faster restore of database.
- switched to github actions instead of Travis
- cronjob on github actions to create pecan/db docker image nightly, will safe also with year-weak (i.e 2020-15)

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
