# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)
require 'rake'

task :log => :environment do
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end

BetyRails3::Application.load_tasks
