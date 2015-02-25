namespace :bety do 
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
end