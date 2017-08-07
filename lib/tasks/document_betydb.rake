# Define the "yard" task:
YARD::Rake::YardocTask.new do |t|
  # Most options are set in the .yardopts file under the Rails root
  # directory rather than here.

  # Uncomment this to get a report of all undocumented methods:
  # t.stats_options = ['--list-undoc']
end

# Make the doc:app task run yardoc instead of RDoc:
namespace :doc do
  task(:app).clear

  desc <<DESCRIPTION
Document the BETYdb app using the Yardoc tool.

Output will be in the doc/app directory.  Options are defined
in #{Rails.root.join(".yardopts")}.

Instead of running "rake doc:app" or "rake yard", you can run the
yardoc command.  This will allow for easily passing options on the
command line.  Run "yardoc --help" for a list of options.

DESCRIPTION
  task :app => :yard
end
