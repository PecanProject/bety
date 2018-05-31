#!/usr/bin/env ruby
# coding: utf-8
USAGE_DETAILS = <<'EOS'

DESCRIPTION

This script attempts to find missing foreign-key constraints by finding column
names of the form "xxx_id" and checking to see if there is an existing
corresponding foreign-key constraint.  Certain columns with names of the form
"xxx_id" that are known not to be foreign keys are filtered out.  A list of
missing foreign-key constraints is printed to standard output.

HOW TO USE

Steps for using the script are as follows:

1. (Optional) Write a YAML file called connection_information.yml in the same
   directory where this script resides that contains database connection
   information, the id number of the machine using the database, and the name of
   a file to write SQL statements to.  See the CONNECTION SPECIFICATION and
   OTHER SCRIPT PARAMETERS sections below.  You may use
   connection_information.yml-sample as a model.  (The correct_machine_id and
   output_file keys are not relevant to this script and will be ignored if
   provided.)

2. Run the script.  A list of missing foreign-key constraints will be printed to
   standard output.

CONNECTION SPECIFICATION

The user should specify connection parameters for the database to be used.
Specifically, the following must be specified:

    host:     The host machine of the database (usually \"localhost\")
    user:     The role name to use to connect to the database
    password: The password for the specified user
    dbname:   The name of the database being connected to
    port:     The port number used for the connection

These may be specified in a YAML file named \"connection_specification.yml\"
having top-level key \"connection_info\" and the above 5 items as sub-keys.  Any
item not specified in the file will be prompted for.  (If the file doesn't
exist, all items will be prompted for.)
  
EOS

## Parse command line

begin
  require 'trollop'
rescue LoadError => e
  puts 'Be sure you have run "bundle install" to install the "trollop" gem.'
  puts 'You may have to prefix this script invocation with "bundle exec"'
  puts
  raise
end

opts = Trollop::options do
  banner <<-EOS
===========================
find_missing_constraints.rb
===========================

Usage:
       find_missing_constraints.rb [options]
where [options] are:
EOS
  opt :help, "Show basic usage information"
  opt :man, "Show complete usage instructions"
end

if opts[:man]

  # modify some Trollop methods:
  module Trollop
    def self.parser
      @last_parser
    end

    # allow Trollop::educate to take a stream parameter
    def self.educate(stream)
      @last_parser.educate(stream)
    end
  end

  require 'stringio'

  # add details to banner:
  Trollop.parser.banner USAGE_DETAILS

  # put the whole banner into a string buffer
  sio = StringIO.new
  Trollop.educate sio

  # use the os's "less" command to display the usage manual
  exec "echo \"#{sio.string}\" | less"
end

require_relative 'lib/enhanced_connection'

# This query finds existing foreign-key constraints in the public namespace.
# Although the SELECT clause has eight columns, only the table_name,
# column_name, and foreign_table_name columns are used in this script.  The
# other columns are there for reference, as they may prove useful in future
# scripts.
FkQuery = <<FK
SELECT
    c.conname AS constraint_name,
    r.relname AS table_name,
    a.attname AS column_name,
    r2.relname AS foreign_table_name,
    a2.attname AS foreign_column_name,
    c.confupdtype,
    c.confdeltype,
    c.convalidated
FROM
    pg_namespace nc
JOIN pg_constraint c
    ON nc.oid = c.connamespace
JOIN pg_class r /* referring table */
    ON c.conrelid = r.oid
JOIN pg_class r2 /* referred-to table */
    ON c.confrelid = r2.oid
JOIN pg_attribute a /* referring column */
    ON a.attnum = ANY(c.conkey) AND c.conrelid = a.attrelid
JOIN pg_attribute a2 /* referred-to column */
    ON a2.attnum = ANY(c.confkey) AND c.confrelid = a2.attrelid
WHERE
    contype = 'f' /* foreign-key constraint */
AND nc.nspname = 'public'; /* public constraint */
FK


IdReferencesQuery = <<IRQ
SELECT table_name, column_name FROM information_schema.columns WHERE table_schema = 'public' AND column_name ~ '_id$' AND is_updatable = 'YES';
IRQ


con = EnhancedConnection.new

con.send_query(FkQuery)

result = con.get_result

existing_fk_info = result.to_a

con.block

con.send_query(IdReferencesQuery)

result = con.get_result

needed_fk_info = result.to_a


needed_fk_info.each do |row|

  table_name = row["table_name"]
  column_name = row["column_name"]

  # columns to ignore
  if ['container_id', # dbfile.container_id references are handled by trigger functions
      'previous_id',  # cultivars.previous_id is a character string; it doesn't reference an id number
      'sync_host_id', # machines.sync_host_id is not a reference
      'session_id'    # sessions.session_id is a hex string identifying a session; it is not a reference
     ].include? column_name
    next
  end

  # Derive name of referred-to table from name of referring column.  (Note
  # special, irregular cases.)
  referred_to_table =
    case column_name
    when 'parent_id', 'previous_id'
      table_name
    when 'entity_id'
      'entities'
    when 'posteriors_samples_id'
      'posterior_samples'
    when 'created_user_id', 'updated_user_id'
      'users'
    when 'trait_variable_id', 'covariate_variable_id'
      'variables'
    else
      column_name[/(.*)_id/, 1] + 's'
    end

  if !con.public_tables.include? referred_to_table
    puts "#{referred_to_table} doesn't exist."
    exit
  end
  
  found = false

  existing_fk_info.each do |row|
    if row["column_name"] == column_name &&
       row["table_name"] == table_name &&
       row["foreign_table_name"] == referred_to_table
      found = true
      break
    end
    
  end
  if !found
    puts "foreign-key constraint for #{table_name}.#{column_name} not found"
  end
  
end

