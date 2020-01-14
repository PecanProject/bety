#!/usr/bin/env ruby
# coding: utf-8

USAGE_DETAILS = <<'EOS'

DESCRIPTION

This script attempts to validate existing CHECK and/or FOREIGN KEY constraints
and prints out the results of the attempt.

BACKGROUND AND EXPLANATION OF OPTIONS

A constraint added to an existing table may be marked NOT VALID when it is added
in an ALTER TABLE statements.  This is a way to grandfather in existing data and
yet have a constraint going forward that will apply to new data (or changes to
old data).  This way, a constraint may be added without first having to clean up
existing data to ensure that it complies with the constraint.

In the default mode ('validate'), the script will find all existing constraints
that have been marked NOT VALID and attempt to validate them by executing the
SQL statement

    ALTER TABLE xxx VALIDATE CONSTRAINT yyy;

where \"yyy\" is the name of the constraint and \"xxx\" is the name of the table it
applies to.  If validation fails, it will print out some information about the
first found instance of an invalid row and go on to attempting to validate the
next constraint.

Revalidation

It may happen that the existing data does not comply with some constraint even
when that constraint was not marked NOT VALID.  This may happen, for instance,
if triggers on a table are temporarily disabled using a statement such as

    ALTER TABLE xxx DISABLE TRIGGER ALL;

And then \"bad\" data is inserted before re-enabling the trigger.

In order to validate such a constraint, we first have to mark it as NOT VALID by
interacting with the convalidated column of the pg_constraints table: issuing an
\"ALTER TABLE xxx VALIDATE CONSTRAINT yyy;\" statement on a constraint that is not
marked NOT VALID has no effect.  (Alternatively, we could drop and then re-add
the constraint with the NOT VALID clause, but manipulating the pg_constraints
table is much easier.)

To validate even those constraints not marked NOT VALID, set the mode option to
\"revalidate\".

Restoring State

By default, running the script will not alter the state of the database:
constraints marked as NOT VALID will be restored to that state even if
validation is successful, and those not marked NOT VALID before the script is
run will be restored to that state even if validation fails.

To only restore NOT VALID constraints that validate, set the restore option to
'not-valid'.  To restore constraints not marked NOT VALID but that don't
validate, use option 'valid'.  To do no restoration at all, use option 'none'.

List Mode

To only list all the constraints of the types specified by the \"types\" option,
use mode \"list\".  This will list each constraint of the designated type(s)—its
name, the name of the table it applies to, and whether it is mareked NOT VALID.

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
===============
fix_database.rb
===============

Usage:
       validate_constraints.rb [options]
where [options] are:
EOS
  opt :help, "Show basic usage information"
  opt :man, "Show complete usage instructions"
  opt :mode, "Either validate, revalidate, or list", default: "validate"
  opt :type, "Either 'check', 'foreign-key', or 'both'", default: "both"
  opt :restore, "Restore constraints marked as valid to that marking even if validation fails ('valid'); and/or restore constraints marked as not valid to that state even if validation succeeds ('not-valid'); to do no restoration, use 'none' and to restore both kinds of constraints, use 'all'", default: "all"
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

Trollop::die :mode, "mode must be 'validate', 'revalidate', or 'list" if !["validate", "revalidate", "list"].include? opts[:mode]
Trollop::die :type, "type must be 'check', 'foreign-key', or 'both'" if !["check", "foreign-key", "both"].include? opts[:type]
Trollop::die :restore, "restore must be 'not-valid', 'valid', 'none', or 'all'" if !["not-valid", "valid", "none", "all"].include? opts[:restore]


require_relative 'lib/enhanced_connection'

ConstraintQuery = <<FK
SELECT
    con.oid AS constraint_oid,
    conname AS constraint_name,
    relname AS table_name,
    convalidated AS validated
FROM
        pg_constraint con
    JOIN
        pg_class pc
    ON pc.oid = con.conrelid
WHERE contype in (%s)
ORDER BY table_name, contype, constraint_name;
FK

SetNotValid = <<SNV
UPDATE
    pg_constraint
SET
    convalidated = 'f'
WHERE
    conname = $1
AND
    (SELECT relname FROM pg_class t WHERE t.oid = conrelid) = $2
SNV

SetValid = <<SV
UPDATE
    pg_constraint
SET
    convalidated = 't'
WHERE
    conname = $1
AND
    (SELECT relname FROM pg_class t WHERE t.oid = conrelid) = $2
SV


con = EnhancedConnection.new

types = case opts[:type]
        when "both"
          "'c', 'f'"
        when "check"
          "'c'"
        when "foreign-key"
          "'f'"
        end
con.send_query(sprintf(ConstraintQuery, types))

result = con.get_result

constraint_list = result.to_a

constraint_list.each do |row|

  validated = (row["validated"] == 't')

  if opts[:mode] == "list"
    printf("CONSTRAINT %s ON TABLE %s IS MARKED %s.\n", row["constraint_name"], row["table_name"], validated == 't' ? "valid" : "not valid")
    next
  end

  if validated && opts[:mode] == "validate"
    next
  end

  con.exec_params(SetNotValid, [row["constraint_name"], row["table_name"]])

  validation_statement = sprintf("ALTER TABLE \"%s\" VALIDATE CONSTRAINT \"%s\";", row["table_name"], row["constraint_name"])
  begin
    con.exec(validation_statement)
    printf("✓ Successfully validated constraint %s on table %s.\n", row["constraint_name"], row["table_name"])

    # If restore option is 'not-valid' or 'all', restore the NOT VALID marker on
    # this constraint even though it validated.
    if !validated && ["all", "not-valid"].include?(opts[:restore])
      con.exec_params(SetNotValid, [row["constraint_name"], row["table_name"]])
    end
  rescue => e
    puts "✗ " + e.to_s

    # If the restore option is 'valid' or 'all', restore constraint to VALID
    # even though it didn't validate.
    if validated && ["all", "valid"].include?(opts[:restore])
      con.exec_params(SetValid, [row["constraint_name"]])
    end
  end
end
