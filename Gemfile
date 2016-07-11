source "http://rubygems.org"

gem "rails", "3.2.22.2"
gem "prototype-rails" # needed for rails 3.1 and above until we phase out prototype
gem "query_reviewer", "0.1.6"
gem "nokogiri"
gem "narray", "0.6.0.4"
gem "choice", "0.1.6"
gem "comma", "3.0.4"
gem "json"
gem "rgeo", "~> 0.5.0"
gem "multi_json", "1.3.6"
gem "railroad", "0.5.0"
gem "recaptcha", "0.3.4", :require => "recaptcha/rails"
gem "ruby-graphviz", "1.0.8"
gem "safe_attributes"
gem "seer", "0.10.0"
gem "tzinfo", "0.3.35"
gem "will_paginate", "3.0.4"
gem "bootstrap-will_paginate"
gem 'rails3-restful-authentication', '~> 3.0.1'
gem 'dynamic_form'
gem 'rabl'
gem 'yajl-ruby'

# to-do: remove prototype dependencies so we no longer need this gem
gem 'prototype_legacy_helper', '0.0.0', :git => 'git://github.com/rails/prototype_legacy_helper.git'

gem 'memoist'

# MySQL, comment out PostgreSQL section
#gem "mysql2"
#gem "ruby-mysql" # for data upload scripts in local
#gem "activerecord-mysql2-adapter"

# Postgresql, comment out MySQL section
gem "pg"
gem "activerecord-postgis-adapter"


gem "trollop" # for Rails scripts


group :development, :test do
  # Although rspec-rails is mainly for the test environment, we
  # include it in development in case we want to have access to
  # RSpec-specific generators.
  gem "rspec-rails", "~> 3.0"
end



group :test do
  # phasing out webrat:    
  # gem "webrat", "0.7.1"
  gem "capybara"
  gem "database_cleaner"
end

# If you have difficulty installing or don't wish to install capybara-webkit,
# run bundle install with the "--without javascript_testing" option:
#
#     bundle install --without javascript_testing
#
group :javascript_testing do
  gem "capybara-webkit", "1.7.1"
end

# This group is used by RSpec if the environment variable RAILS_DEBUG is set to
# "true":
group :debug do
  gem "selenium-webdriver"
  gem "pry"
end

# Comment this out if you can't or don't wish to install capybara-webkit:

group :production do
#  gem "rmagick", "2.13.1"
  gem "passenger"
end

# API-related Gems:

gem "rspec_api_documentation"
gem "json-schema" # needed by rspec_api_documentation

gem "apipie-rails"
gem "test-unit" # seems to be needed by apipie-rails and prototype-rails

