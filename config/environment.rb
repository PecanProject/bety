# Load the rails application
require File.expand_path('../application', __FILE__)

# Load customization settings:
if File.exists?(File.join(File.dirname(__FILE__), 'customization.rb'))
  require_relative 'customization'
else
  puts "YOU MUST HAVE A CUSTOMIZATION FILE \"config/customization.rb\".\nSee \"config/customization.rb.template\" for an example."
  exit
end

# Initialize the rails application
BetyRails3::Application.initialize!

# config/initializers/bigint_primary_keys.rb
ActiveRecord::Base.establish_connection
if defined? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
  ActiveRecord::ConnectionAdapters::PostgreSQLAdapter::NATIVE_DATABASE_TYPES[:primary_key] = 'bigserial primary key'
end
if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
  ActiveRecord::ConnectionAdapters::Mysql2Adapter::NATIVE_DATABASE_TYPES[:primary_key] = "BIGINT UNSIGNED DEFAULT NULL auto_increment PRIMARY KEY"
end
