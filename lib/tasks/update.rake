namespace :bety do
  desc "Update schema"
  task :update do
    `#{Rails.root.join('update.sh')}`
    puts "Schema update completed"
  end
  
  desc "create api key for users without one"
  task :make_keys => :environment do
    users = User.where("apikey is NULL")
    users.each do |user|
      apikey = (0...40).collect { ((48..57).to_a + (65..90).to_a + (97..122).to_a)[Kernel.rand(62)].chr }.join
      user.apikey = apikey
      if user.save
        ContactMailer::apikey_email(user).deliver
      end
    end
    puts "api key created for every user"
  end

  # automatically update schema on a migration
  Rake::Task["db:migrate"].enhance do
    Rake::Task["bety:update"].invoke
  end
end