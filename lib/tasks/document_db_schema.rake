namespace :bety do

  desc "Generate or update the documentation of the database scheme."
  task :dbdocs => [:schema_spy_config] do
    config = Rails.configuration.database_configuration[@rails_env]
    host     = config["host"]
    database = config["database"]
    username = config["username"]
    password = config["password"]

    sh "#{@java} -jar #{@schemaSpy} "             +
      "-t pgsql "                                 +
      "-host #{host || "localhost"} "             +
      "-dp #{@driver} "                           +
      "-db #{database} "                          +
      "-s public "                                +
      "-u #{username} "                           +
      "#{password.nil? ? "" : "-p #{password}"} " +
      "-o #{@outdir}"

    if @remove_root_dir_files
      FileUtils.rm([ "#{@outdir}/deletionOrder.txt", "#{@outdir}/insertionOrder.txt",
                     "#{@outdir}/bety.public.xml", "#{@outdir}/schemaSpy.css" ]) 
    end 

  end

  task :schema_spy_config do
    begin
      require_relative 'schemaSpyConfig.rb'
    rescue LoadError => e
      puts <<MESSAGE

You must make a schemaSpyConfig.rb file to generate database documentation!
See the template file
    #{Rails.root}/lib/tasks/ schemaSpyConfigTemplate.rb
for details.

MESSAGE
      exit
    end

    if @skip_schema_spy_run
      exit
    end

    if @outdir.nil? || @schemaSpy.nil? || @driver.nil?
      puts "You must set @outdir, @schemaSpy, and @driver in your schemaSpyConfig.rb file."
      exit
    end

    if @rails_env.nil?
      @rails_env = Rails.env
    end

  end # task :config

end # namespace :bety

# automatically update schema on a migration
Rake::Task["db:migrate"].enhance do
  Rake::Task["bety:dbdocs"].invoke
end
