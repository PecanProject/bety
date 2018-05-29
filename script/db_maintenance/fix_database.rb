#!/usr/bin/env ruby
# coding: utf-8

# This script generates a file of SQL statements to fix the sequence objects and
# public table ids for a specified BETYdb database.  It assumes id numbers were
# misallocated in the 99 billion range and that rows having ids in that range
# should be reassigned an id number in the range appropriate to the machine
# specified by the user.
#
# Database connection information may either be specified in a YAML file
# "connection_information.yml" (see "connection_information.yml-sample" for an
# example) or prompted for interactively.  The user should also specify the
# number of the target machine and the name of the file to write the SQL
# statements to.
#
# Steps for using the script are as follows:
#
# 1. Take BETYdb instance that uses the target database off line.
#
# 2. Run the script.
#
# 3. Check that there are appropriate foreign-key constraints on all tables that
#    refer to any table mentioned in any of the generated UPDATE statements.
#    These foreign-key constraints should use the "ON UPDATE CASCADE" clause.
#
# 4. If the necessary constraints are present, run the SQL statements in the generated file.
#
# 5. Restore the BETYdb instance that was taken off line in step 1.
#

USAGE_DETAILS = <<'EOS'

DESCRIPTION

This script generates a file of SQL statements to fix the sequence objects and
table ids in the public schema of the specified BETYdb database.  It assumes id
numbers were mis-allocated in the 99 billion range and that rows having ids in
that range should be reassigned id numbers in the range appropriate to the
machine specified by the user (see \"correct_machine_id\" below).

Database connection information may either be specified in a YAML file
\"connection_information.yml\" (see \"connection_information.yml-sample\" for an
example) or prompted for interactively.  The user should also specify the number
of the target machine and the name of the file to write the SQL statements to.

Steps for using the script are as follows:

1. Take BETYdb instance that uses the target database off line.

2. Run the script.

3. Check that there are appropriate foreign-key constraints on all tables that
   refer to any table mentioned in any of the generated UPDATE statements.
   These foreign-key constraints should use the \"ON UPDATE CASCADE\" clause.

4. If the necessary constraints are present, run the SQL statements in the
   generated file.

5. Restore the BETYdb instance that was taken off line in step 1.


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

OTHER SCRIPT PARAMETERS

In addition to database connection parameters, the user must provide:

    correct_machine_id: The machine id for the machine using the specified
                        database

    output_file:        The name of the file to which SQL statements should be
                        written

These may be specified as top-level keys in the YAML file.  Otherwise, they are
prompted for.
  
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
===============
fix_database.rb
===============

Usage:
       fix_database.rb [options]
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

require_relative 'lib/id_fixer'

con = IdFixer.new

con.generate_sql_fix_statements
