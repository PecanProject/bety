namespace :bety do 
  desc "create api key for users without one"
  task :make_keys => :environment do
    users = User.where("apikey is NULL")
    users.each do |user|
      user.create_apikey
      if user.save
        ContactMailer::apikey_email(user).deliver
      end
    end
    puts "api key created for every user"
  end
end