source "http://rubygems.org"

gem "rails", "5.1.7"
# needed for rails 3.1 and above until we phase out prototype:
## gem 'prototype-rails', github: 'rails/prototype-rails', branch: '4.2' # see https://github.com/rails/prototype-rails/issues/37
gem "nokogiri"
gem "narray", "0.6.0.4"
gem "choice", "0.1.6"
gem "comma", "~> 4.3.2"
gem "json"
gem "rgeo", "~> 0.5.0"
gem "multi_json"
gem "railroad", "0.5.0"
gem "recaptcha", "4.8.0", :require => "recaptcha/rails"
gem "ruby-graphviz", "1.0.8"
gem "safe_attributes"
gem "seer", "0.10.0"
gem "tzinfo"
gem "will_paginate"
gem "bootstrap-will_paginate"
gem 'rails3-restful-authentication', '~> 3.0.1'
gem 'dynamic_form'
gem 'rabl'
gem 'yajl-ruby', '~> 1.3.1'
gem 'rubyzip', '~> 1.3.0'
gem 'activerecord-session_store' # no longer part of Rails proper
gem 'protected_attributes_continued' # Use this until and unless we start using Strong Parameters.
gem 'sass-rails'
gem 'coffee-rails'
gem 'uglifier'
gem 'activemodel-serializers-xml' # no longer part of Rails proper as of Rails 5

gem 'jquery-rails'
gem 'jquery-ui-rails'

gem 'memoist'

# MySQL, comment out PostgreSQL section
#gem "mysql2"
#gem "ruby-mysql" # for data upload scripts in local
#gem "activerecord-mysql2-adapter"

# Postgresql, comment out MySQL section
gem "pg"
gem "activerecord-postgis-adapter"


gem "optimist" # for Rails scripts


group :development, :test do
  # Although rspec-rails is mainly for the test environment, we
  # include it in development in case we want to have access to
  # RSpec-specific generators.
  gem "rspec-rails", "~> 3.0"
  gem "yard"
end

group :development, :test do
  gem "pry-rails"
  gem "pry-byebug"
end

group :test do
  # phasing out webrat:    
  # gem "webrat", "0.7.1"
  gem "capybara", "~> 2.8"
  gem "database_cleaner"
  gem "rails-controller-testing" # TO-DO: rewrite the specs that rely on this
end

# If you have difficulty installing or don't wish to install capybara-webkit,
# run bundle install with the "--without javascript_testing" option:
#
#     bundle install --without javascript_testing
#
group :javascript_testing do
  gem "capybara-webkit", "~>1.7"
end

# This group is used by RSpec if the environment variable RAILS_DEBUG is set to
# "true":
group :debug do
  gem "selenium-webdriver"
  gem "pry"
end

group :production do
  gem "passenger"
end

group :docker do
  gem 'unicorn'
end

# API-related Gems:

gem "rspec_api_documentation"
gem "json-schema" # needed by rspec_api_documentation

gem "apipie-rails", "0.5.6"

# Although it was previously noted that test-unit seems to be needed by
# apipie-rails and prototype-rails, it interferes with routing specs, so we are
# commenting it out for now.
## gem "test-unit"

