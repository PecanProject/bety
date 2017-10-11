namespace :bety do

  namespace :db do
    
    # This is a subsidiary task.  It should be a prerequisite for any
    # task that calls the table_2_model method.  It loads each model
    # found in the app/models directory.
    task :load_models => :environment do
      Dir.foreach(Rails.root.join("app", "models")) do |f|
        begin
          if f =~ /.*\.rb$/
            require f
          end
        rescue LoadError => e
          puts e
        end
      end
    end


    # Returns a Hash whose keys are all the tables having a Rails model
    # and whose values are the model object itself.
    def table_2_model
      return Hash[ActiveRecord::Base.send(:descendants).collect{|model| [model.table_name, model]}]
    end


    desc <<DESCRIPTION
Update database comments using the data in the YAML file db/data/database_comments.yaml.
DESCRIPTION
    task :update_comments => [ "rake:db:load_config", :load_models ] do

      begin
        comments = YAML::load(File.open(Rails.root.join('db', 'data', 'database_comments.yaml')))

        config = ActiveRecord::Base.configurations[Rails.env]
        connection = ActiveRecord::Base.establish_connection(config).connection

        table_2_model = Hash[ActiveRecord::Base.send(:descendants).collect{|model| [model.table_name, model]}]


        comments.each_pair do |table, value|

          if !connection.tables.include? table
            puts "There is no table named \"#{table}\" ... skipping ..."
            next
          end

          value.each_pair do |key, comment|
            if key == "table_comment"
              connection.exec_query("COMMENT ON TABLE \"#{table}\" IS #{ActiveRecord::Base.sanitize(comment)}")
            elsif table_2_model[table].column_names.include? key
              connection.exec_query("COMMENT ON COLUMN \"#{table}\".\"#{key}\" IS #{ActiveRecord::Base.sanitize(comment)}")
            else
              puts "The \"#{table}\" table does not have a column named \"#{key}\" ... skipping ..."
            end
          end
        end

      rescue Psych::SyntaxError => e
        puts e.inspect
        puts e.message
        exit
      rescue PG::ConnectionBad => e
        puts e.message
      end
    end


    desc <<DESCRIPTION
Dump the collection of database table and column comments as a YAML \
file.

The file will be dumped to db/data/database_comments.yaml.dump.

The top-level keys in this file will be some or all of the table
names.  The corresponding values will be collections of key-value
pairs, including keys corresponding to some or all of the table
columns plus the special key "table_comment"; the corresponding values
in the pairs will be the comments themselves.  Keys for table columns
will be produced only for tables having a Rails model.

A dump file may be used with the "bety:update_comments" task to
replicate the set of comments present in the database at the time the
dump was made.

This tasks takes up to three arguments:

* mode: either "complete" (the default) or "minimal".

  A complete dump will produce a key for each table, whether or not
  there are comments on the table or its columns, and a key for each
  column of each table (except those tables for which there is no
  Rails model).  A minimal dump produces table keys only for those
  tables having a table comment or a comment on at least one column.
  It produces column keys only for columns having a comment.

* column_order: either "alphabetical" or "sql" (the default).

  By default, the keys corresponding to the columns of the table will
  be listed in the order corresponding to the SQL table definition.
  To alphabetize them instead, use the argument "alphabetical".

* quiet: either 'true' or 'false' (the default).

  Set this parameter to "true" to suppress error messages.
DESCRIPTION
    task :dump_comments, [:mode, :column_order, :quiet] => ["rake:db:load_config", :load_models, :environment ] do |t, args|

      args.with_defaults(:mode => 'complete', :column_order => 'sql', :quiet => 'false')

      if !['minimal', 'complete'].include? args.mode
        puts 'The first argument (mode) should be either "minimal" or "complete".'
        exit
      end

      if !['alphabetical', 'sql'].include? args.column_order
        puts 'The second argument (column_order) should be either "alphabetical" or "sql".'
      end

      if !['true', 'false'].include? args.quiet
        puts "The third argument (quiet) should be either true or false."
      end

      # Get connection for the current environment:
      config = ActiveRecord::Base.configurations[Rails.env]
      connection = ActiveRecord::Base.establish_connection(config).connection

      # main Hash
      comment_hash = Hash.new

      # iterate through all tables
      connection.tables.sort.each do |table|

        comment_hash_for_this_table = Hash.new

        table_comment =  Utilities::SQLComments.get_table_description(table)

        if args.mode == 'complete' || table_comment
          comment_hash_for_this_table["table_comment"] = table_comment
        end

        # Needed for getting column names:
        model = table_2_model[table]

        if !model.nil?

          table_has_comments = false

          column_names = model.column_names

          if args.column_order == 'alphabetical'
            column_names.sort!
          end

          column_names.each do |column|

            column_comment = Utilities::SQLComments.get_column_comment(table, column)

            table_has_comments ||= !column_comment.nil?

            if args.mode == 'complete' || column_comment
              comment_hash_for_this_table[column] = column_comment
            end

          end # column iteration

        elsif args.quiet == 'false'
          puts "Can't find a model for the table \"#{table}\" ... skipping column comments ..."
        end

        if comment_hash_for_this_table.keys.size > 0
          comment_hash[table] = comment_hash_for_this_table
        end

      end # table iteration

      File.write(Rails.root.join("db", "data", "database_comments.yaml.dump"), YAML.dump(comment_hash))

    end # dump_comments task

  end # namespace db

end # namespace bety
