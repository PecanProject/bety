namespace :bety do
  desc "Update schema"
  task :update do
    `#{Rails.root.join('update.sh')}`
    puts "Schema update completed"
  end
  # automatically update schema on a migration
  Rake::Task["db:migrate"].enhance do
    Rake::Task["bety:update"].invoke
  end
end