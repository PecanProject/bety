namespace :bety do

  ### METHODS ###

  # Things we may want to run more than once are defined as methods.

  def run_schema_spy
    ensure_parameters_are_set

    host     = @config["host"]
    database = @config["database"]
    username = @config["username"]
    password = @config["password"]

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
                     "#{@outdir}/#{database}.public.xml", "#{@outdir}/schemaSpy.css" ]) 
    end 
  end

  def ensure_parameters_are_set
    if @java.blank? || @schemaSpy.blank? || @driver.blank? || @outdir.blank?
      if @java.blank?
        puts "No setting was given for java_executable."
      end
      if @schemaSpy.blank?
        puts "No setting was given for schema_spy_jar_file."
      end
      if @driver.blank?
        puts "No setting was given for postgresql_driver_jar_file."
      end
      if @outdir.blank?
        puts "No setting was given for output_directory."
      end
      abort
    end
  end

  def set_configuration_instance_variables_from_yaml_file(version)
    settings = CONFIG[:schema_spy_settings]
    settings.merge! settings.fetch(version, {dintwork: version})

    if @debug
      puts "\nschema-spy settings from YAML configuration file: #{settings}\n\n"
    end

    @java = settings[:java_executable]
    @schemaSpy = settings[:schema_spy_jar_file]
    @driver = settings[:postgresql_driver_jar_file]
    @outdir = settings[:output_directory]
    @remove_root_dir_files = settings[:remove_root_dir_files]
  end

  ### TASKS ###

  desc <<DESCRIPTION
Generate or update the documentation of the database scheme.

This task builds the SchemaSpy documentation for the current Rails environment's
database.  In order to run the build, you must tell SchemaSpy the following:

  1. Where the SchemaSpy Jar file is.
  2. Where the Java executable is.
  3. Where the Jar file for the PostgreSQL JDBC driver is.
  4. What directory to use for the output.
  5. Optionally, whether to remove certain files from the output (the default is not to).

How to do this is explained below.

There are two versions of the documentation that may be built:

  * A customized version of the documentation that is integrated with the BETYdb
    Web application ('CUSTOM').

  * The original version of the SchemaSpy Jar file ('FULL').  This provides more
    extensive documentation but is not as well integrated with the BETYdb Web
    application.  This version of the Jar file may be downloaded from
    https://sourceforge.net/projects/schemaspy/files/schemaspy/.

The environment variable SCHEMA_SPY_VERSIONS determines which versions the task
will build.  It may be set to 'CUSTOM', 'FULL', or 'BOTH'.  If unset, both
versions will be built.

Configuration settings should be put in the YAML configuration file
config/application.yml.  The general format of this section of the file is

    schema_spy_settings:
        java_executable: java
        postgresql_driver_jar_file: ~/Applications/SchemaSpy/postgresql-9.3-1103.jdbc41.jar

        settings_for_full_documentation:
           schema_spy_jar_file: ~/Applications/SchemaSpy/schemaSpy_5.0.0.jar
           output_directory: public/db_docs
           remove_root_dir_files: false

        settings_for_customized_documentation:
           schema_spy_jar_file: ~/Applications/SchemaSpy/schemaSpy.jar
           output_directory: .
           remove_root_dir_files: true

Settings common to both the full and customized builds go directly under the
":schema_spy_settings" key.  Settings specific to the FULL or CUSTOM version go
under the subkeys ":settings_for_full_documentation" or
":settings_for_customized_documentation", respectively.  (Since version-specific
values override values specified at the "common" level, only one of these
version-specific groups of settings is strictly necessary; but providing both
makes for greater clarity.)

If no version-specific group is provided, the task will only do one build, even
it SCHEMA_SPY_VERSIONS=BOTH was specified.  Note that it is up to the user to
ensure that the settings for the customized and full versions really do
correspond to the CUSTOM and FULL versions defined above.  If the top-level key
":schema_spy_settings" is not found, the task will attempt to set configuration
parameters by loading the file lib/tasks/schemaSpyConfig.rb.  This behavior is
somewhat deprecated; using config/application.yml is now the preferred method of
providing configuration settings.  Nevertheless, reading the template file
lib/tasks/schemaSpyConfigTemplate.rb may provide useful additional information
even if ultimately, adding to the YAML file is the method chosen for specifying
configuration settings.

The customized version of the Jar file requires that the build must be done with
Java SE 8.  (Later releases may also work when they become available.)  When
building the customized version of the documentation, the output directory
should be set to ".".  For the customized version, ":remove_root_dir_files"
should be set to true since these files are not useful for that version and only
clutter up the root directory.

The JDBC driver files may be obtained from
https://jdbc.postgresql.org/download.html.  Version 9.3-1103 JDBC 41 is
compatible both with PostgreSQL 9.3 and with Java SE 8.
DESCRIPTION
  task :dbdocs, [:debug] => [:set_debug_value, :set_db_config] do |t, args|

    if CONFIG.has_key?(:schema_spy_settings)

      if ENV.has_key?('SCHEMA_SPY_VERSIONS')
        versions_to_make = ENV['SCHEMA_SPY_VERSIONS']
        if !['BOTH', 'FULL', 'CUSTOM'].include? versions_to_make
          abort "Unrecognized value \"#{versions_to_make}\" for SCHEMA_SPY_VERSIONS." +
            "\nUse 'FULL', 'CUSTOM', or 'BOTH'."
        end
      else
        versions_to_make = 'BOTH'
      end

      case versions_to_make
      when 'CUSTOM'
        puts 'Making customized version of SchemaSpy documentation ...'
        Rake::Task['bety:customized_dbdocs'].invoke
      when 'FULL'
        puts 'Making full version of SchemaSpy documentation ...'
        Rake::Task['bety:full_dbdocs'].invoke
      when 'BOTH'
        if (CONFIG[:schema_spy_settings].has_key?(:settings_for_full_documentation) ||
            CONFIG[:schema_spy_settings].has_key?(:settings_for_customized_documentation))

          puts 'Making customized version of SchemaSpy documentation ...'
          Rake::Task['bety:customized_dbdocs'].invoke
          puts 'Making full version of SchemaSpy documentation ...'
          Rake::Task['bety:full_dbdocs'].invoke

        else
          # There is really only one set of configuration settings, so just do one build:
          Rake::Task['bety:customized_dbdocs'].invoke
        end
      end # case
=begin
      if ['BOTH', 'CUSTOM'].include? versions_to_make
        puts 'Making customized version of SchemaSpy documentation ...'
        Rake::Task['bety:customized_dbdocs'].invoke
      end

      if ['BOTH', 'FULL'].include? versions_to_make
        puts 'Making full version of SchemaSpy documentation ...'
        Rake::Task['bety:full_dbdocs'].invoke
      end
=end
    else # Use the settings in schemaSpyConfig.rb.  This is somewhat deprecated.

      Rake::Task['bety:set_configuration_instance_variables_from_schemaSpyConfig_file'].invoke
      run_schema_spy

    end
  end

  

  # All of the remaining tasks are subsidiary tasks, meant only to be called
  # from the bety:dbdocs task.

  task :full_dbdocs => [:full_config] do
    run_schema_spy
  end

  task :customized_dbdocs => [:custom_config] do
    run_schema_spy
  end

  task :full_config do
    set_configuration_instance_variables_from_yaml_file(:settings_for_full_documentation)
  end

  task :set_debug_value, [:debug] do |t, args|
    if args[:debug] == "debug"
      @debug = true
    else
      @debug = false
    end
  end

  task :set_db_config do
    @config = Rails.configuration.database_configuration[Rails.env]
    if @debug
      puts "Database configuration: #{@config}"
    end
  end

  task :custom_config do
    set_configuration_instance_variables_from_yaml_file(:settings_for_customized_documentation)
  end

  task :set_configuration_instance_variables_from_schemaSpyConfig_file do
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
    end # begin/rescue block

    if @skip_schema_spy_run
      exit
    end

    if @outdir.nil? || @schemaSpy.nil? || @driver.nil?
      puts "You must set @outdir, @schemaSpy, and @driver in your schemaSpyConfig.rb file."
      exit
    end

    if @java.nil?
      @java = "java"
    end

  end # task :config

end # namespace :bety


desc <<DESCRIPTION
This task has been modified to automatically build the SchemaSpy documentation
upon successful completion of a migration.  To disable this behavior, set the
enviroment variable SKIP_SCHEMASPY to YES."
DESCRIPTION
task "db:migrate"
Rake::Task["db:migrate"].enhance do
  if !ENV.has_key?('SKIP_SCHEMASPY') || ENV['SKIP_SCHEMASPY'] == "NO"
    puts <<MESSAGE

About to build the SchemaSpy documentation.  
To skip this when doing migrations, invoke the migration task as 

    rake db:migrate SKIP_SCHEMASPY=YES [RAILS_ENV=(development|test|production)]

MESSAGE
    Rake::Task["bety:dbdocs"].invoke
  elsif ENV.has_key?('SKIP_SCHEMASPY') && ENV['SKIP_SCHEMASPY'] != "YES"
    abort "Invalid value for SKIP_SCHEMASPY.  Use 'YES' or 'NO'."
  end
end
