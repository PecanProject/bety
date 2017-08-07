# Define the "yard" task:
YARD::Rake::YardocTask.new do |t|
  t.files   = ['lib/**/*.rb', 'app/**/*.rb']#OTHER_PATHS]   # optional
  t.options = ['--private', '--any', '--extra', '--opts'] # optional
  t.stats_options = ['--list-undoc']         # optional
end

# Make the doc:app task run yardoc instead of RDoc:
namespace :doc do
  task(:app).clear
  task :app => :yard
end
