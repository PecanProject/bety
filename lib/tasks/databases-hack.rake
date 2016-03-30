# An incompatibility between the active-record-3.2.21 and
# activerecord-postgis-adapter-0.6.6 rails3 rake files makes these
# hacks necessary.

# The definition of db:test:load_structure given at
# "gems/activerecord-3.2.21/lib/active_record/railties/databases.rake:501"
# runs its prerequisite (db:test:purge) and then calls
# db:structure:load.  But this task--db:structure:load--is overriden
# for the postgis adapter in
# "gems/activerecord-postgis-adapter-0.6.6/lib/active_record/connection_adapters/postgis_adapter/rails3/databases.rake"
# in a way that doesn't set the configuration correctly.  So we
# override the actions and run the structure file directly.
::RGeo::ActiveRecord::TaskHacker.modify('db:test:load_structure', 'test', 'postgis') do |config_|

  #for debugging:
  #puts "config_ = #{config_}"
  #puts "::Rails.env = #{::Rails.env}"

  set_psql_env(config_)
  `psql -U "#{config_["username"]}" -f #{::Rails.root}/db/#{::Rails.env}_structure.sql #{config_["database"]}`
end

# gems/activerecord-3.2.21/lib/active_record/railties/databases.rake:521
# defines db:test:clone_structure with prerequisites db:structure:dump
# and db:test:load_structure and no actions.  The postgis adapter Gem
# overrides this in
# "gems/activerecord-postgis-adapter-0.6.6/lib/active_record/connection_adapters/postgis_adapter/rails3/databases.rake",
# adding an action to set run the structure file directly.  This is
# redundant, so we clear out that action.
Rake::Task["db:test:clone_structure"].clear_actions


# Add descriptions for test-database-related tasks:
Rake::Task["db:test:load_structure"].add_description(<<DESC
Loads the test database with database structure defined in the file "db/<RAILS_ENV>_structure.sql",
where RAILS_ENV is the current Rails environment.  It will first run
db:test:purge to drop the test database (if it exists) and then
recreate it.
DESC
)

Rake::Task["db:test:clone_structure"].add_description(<<DESC
Clones the structure of the current environment and then loads it into the test database.
It will first run db:test:purge to drop the test database (if it exists) and
recreate it.  Then it creates (or recreates) the structure.sql file for the
current environment ("db/<RAILS_ENV>_structure.sql") and loads it into the test
database.
DESC
)

namespace :db do
  namespace :fixtures do
    task :load => :block_for_non_test_env

    task :block_for_non_test_env do
      if Rails.env != 'test'
        raise "Loading fixtures has been disabled for all environments other than the test environment."
      end
    end
  end
end
