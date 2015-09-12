# An incompatibility between the active-record-3.2.21 and
# activerecord-postgis-adapter-0.6.6 rails3 rake files makes this hack necessary
# in order to avoid a problem where the postgis adapter's db:structure:load task
# tries to run the development_structure.rb file on the development database
# rather than the test database, even when called from the
# db:test:load_structure task.  This results in a slough of (probably harmless)
# errors about having multiple primary keys and about functions, relations,
# triggers, and constraints that already exist.

Rake::Task["db:test:load_structure"].clear_actions
