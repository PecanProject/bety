# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
BetyRails3::Application.initialize!

# config/initializers/bigint_primary_keys.rb
ActiveRecord::Base.establish_connection
if defined? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:primary_key] = 'bigserial primary key'
end
if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
  ActiveRecord::ConnectionAdapters::Mysql2Adapter::NATIVE_DATABASE_TYPES[:primary_key] = "BIGINT UNSIGNED DEFAULT NULL auto_increment PRIMARY KEY"
end
