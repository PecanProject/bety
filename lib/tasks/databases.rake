# Task for ensuring script/load.bety.sh exists
file "script/load.bety.sh" do
  puts "downloading load.bety.sh"
  url = "https://raw.githubusercontent.com/PecanProject/pecan/master/scripts/load.bety.sh"
  `cd script && curl -LOs #{url}`

  # curl may create a load.bety.sh file with contents "Not Found" if we get a 404 error.
  script_file = File.open("script/load.bety.sh")
  if script_file.grep(/Not Found/).size >= 1
    script_file.rewind
    puts "curl #{url}: #{script_file.read}"
    script_file.close
    File.delete("script/load.bety.sha")
    raise "Couldn't get load.bety.sh script"
  end
end

# This is just like the original version except that if Rails.env is
# "development", this version (unlike the original) doesn't try to create the
# test database as well.
::RGeo::ActiveRecord::TaskHacker.modify('db:create', nil, 'postgis') do
  if ENV['DATABASE_URL']
    create_database(database_url_config)
  else
    config = ActiveRecord::Base.configurations[Rails.env]
    create_database(config)
    ActiveRecord::Base.establish_connection(configs_for_environment.first)
  end
end





namespace :bety do
  namespace :db do

    # Task for ensuring script/load.bety.sh exists and is executable
    task :enable_load_execution => "script/load.bety.sh" do
      output = `chmod +x script/load.bety.sh`
      puts output
    end

    desc <<DESCRIPTION
Populate the database for the current Rails environment as specified in config/database.yml.
This uses the load.bety.sh script.  If load.bety.sh is missing from the script
directory, download a fresh copy.  If the database doesn't yet exist, it is
created.  Use the RAILS_ENV=<env> option to populate the database for an
environment other than the current one.  When connecting to the database, the
user specified in database.yml as "su_username" will be used if it exists,
otherwise user "postgres" is used.  If this fails, the user specified in
database.yml by "username" will be used.
DESCRIPTION
    task :populate => [ :enable_load_execution, "rake:db:create", "rake:db:load_config" ] do
      puts "Populating the #{Rails.env} database."
      config = ActiveRecord::Base.configurations[Rails.env]
      superuser = config['su_username'] || 'postgres'
      host = config['host'] || 'localhost'
      port = config['port'] || 5432
      owner = config['username']
      ActiveRecord::Base.establish_connection(config.merge("username" => superuser))
      begin
        ActiveRecord::Base.connection
      rescue => e
        # As a last resort, reset superuser to the user specified by username:
        superuser = config['username']
      end
      `#{Rails.root}/script/load.bety.sh -a #{superuser} -p "-h #{host} -p #{port}" -o #{owner} -c -u -g`
    end
  end
end

