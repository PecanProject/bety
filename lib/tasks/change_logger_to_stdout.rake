
desc <<DESCRIPTION
Change logger to STDOUT

      When this task is listed command line, tasks following it will be logged
      to STDOUT instead of to the default log file.  In particular, using this
      with the migration task ("rake log db:migrate") will display what SQL
      commands are run to effect the migration.
      
DESCRIPTION
task :log => :environment do
  ActiveRecord::Base.logger = Logger.new(STDOUT)
end
