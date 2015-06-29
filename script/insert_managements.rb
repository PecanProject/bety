#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

# define constants
REQUIRED_HEADINGS = ['citation_author', 'citation_title', 'citation_year', 'treatment_name', 'mgmttype']
OPTIONAL_HEADINGS = [ 'date', 'dateloc', 'level', 'units', 'notes' ]
RECOGNIZED_HEADINGS = REQUIRED_HEADINGS + OPTIONAL_HEADINGS


MANAGEMENT_INSERT_TEMPLATE = <<SQL
INSERT INTO managements (citation_id, date, dateloc, mgmttype, level, units, notes, user_id)
                 VALUES ( %i, %s, %s, %s, %s, %s, %s, %i );
SQL

MANAGEMENTS_TREATMENTS_INSERT_TEMPLATE = <<SQL
INSERT INTO managements_treatments (treatment_id, management_id)
                            VALUES ( %i, LASTVAL() );
SQL

USAGE_DETAILS = <<-EOS

DESCRIPTION

This script takes a CSV file describing managments to be added to the database
as input and outputs a file containing SQL statements to do the required
insertions.

CSV FILE FORMAT

The CSV file must contain the following column headings:

\t#{REQUIRED_HEADINGS.join("\n\t")}

Each row must have non-empty values in each of these columns.  Moreover, the
citation columns must match exactly one row in the citations row of the database
and the treatment name must match exactly one of the treatment rows associated
with the matched citation.

Additionally, the CSV file MAY contain the following column headings:

\t#{OPTIONAL_HEADINGS.join("\n\t")}

Each optional column heading corresponds to a column in the database managements
table.  Values in these columns may be left blank in any given row.  For these
columns, if a column value is left blank, or if the column is not included in
the CSV file, the resulting column value in the database will be the SQL-defined
default value for that column.

DATABASE SPECIFICATION

The database used by the script is determined by the environment specified by
the '--environment' option (or 'development' if not specified) and the contents
of the configuration file 'config/database.yml'.  (Run 'rake dbconf' to view the
contents of this file on the command line.)

USING THE SCRIPT TO UPDATE THE PRODUCTION DATABASE

There are essentially three options for using this script to update the
production database.

Option A: Run the script on the production server in the Rails root directory of
the production deployment of the BETYdb Rails app.

In detail:

1. Upload the input CSV file to the production machine.

2. Log in to the production machine and cd to the root directory of production
   deployment of the BETYdb Rails app.

3. Run the script using the '--environment=production' option and with '--login'
   set to your own BETYdb Rails login for the production deployment.  The
   command-line argument specifying the input CSV file path should match the
   location you uploaded it to.

4. After examining the resulting output file, apply it to the database with the
   command

       psql <production database name>  <  <output file name>

(If your machine login doesn't match a PostgreSQL user name that has insert
permissions on the production database, you will have to use the '-U' option to
specify a user who does have such permission.)


Option B: Run the script on your local machine using an up-to-date copy of the
BETYdb database.

To do this:

1. Switch to the root of the copy of the BETYdb Rails app you want to use.

2. For the copy of the BETYdb database connected to this copy of the Rails app,
   ensure that at least the citations and the treatments tables are up-to-date
   with the production copy of the BETYdb database.  (If you have different
   databases specified for your development and your production environments, be
   sure that the enviroment you specify with the '--environment' option points
   to the right database.)

3. Run this script.

4. Upload the output file to the production server and apply it to the
   production database using the psql command given above.


Option C: Run the script on your local machine using a Rails environment
connected to the production database.

1. Go to the copy of the BETYdb Rail app on your local machine that you wish to
   use.

2. Edit the file config/database.yml, adding the following section:

ebi:
  adapter: postgis
  encoding: utf8
  reconnect: false
  database: <production database name>
  pool: 5
  username: <user name for connecting to the production database>
  password: <password for the user specified above>
  port: 8000
  host: localhost

Most of these values can be copied from the production copy config/database.yml
if you have access to it.  The port and host entries are 'new'.

3. Set up an ssh tunnel to the production server using the command

ssh -L 8000:<production server address>:5432 <production server address>

This will log you into the production server, but at the same time it will
connect port 8000 on your local machine with port 5432 (the PostgreSQL server
port) on the production machine.  (The choice of 8000 for port number is
somewhat arbitrary, but whatever value you use should match the value you
specified for the port number in the database.yml file.)

4. Run this script with the environment option '--environment=ebi'.  (Again, the
name 'ebi' for the environment is somewhat arbitrary, but the option value
should match the name in your database.yml file.)

5. Continue as in step 4 under option B.
 
EOS



# helper methods

def get_citation_from_row(row_as_hash)

  citations = Citation.where({ author: row_as_hash["citation_author"], year: row_as_hash["citation_year"], title: row_as_hash["citation_title"] })

  if citations.size == 0
    puts sprintf("No citation with author %s, year %s, and title %s was found.", row_as_hash["citation_author"], row_as_hash["citation_year"], row_as_hash["citation_title"])
    raise "Citation not found"
  elsif citations.size > 1
    puts sprintf("Multiple citations with author %s, year %s, and title %s were found.  Quitting.", row_as_hash["citation_author"], row_as_hash["citation_year"], row_as_hash["citation_title"])
    exit
  else
    c = citations[0]
  end

  puts c

  return c

end


def get_treatment_for_citation_and_row(citation, row_as_hash)

  treatments = citation.treatments.find_all_by_name(row_as_hash["treatment_name"])


  if treatments.size == 0
    puts sprintf("No treatment with name %s was found.", row_as_hash["treatment_name"])
    raise "Treatment not found"
  elsif treatments.size > 1
    puts sprintf("Multiple treatments with name %s were found.", row_as_hash["treatment_name"])
    exit
  else
    t = treatments[0]
  end

  puts t

  return t

end

def csvrow_to_input_statements(row_as_hash)

  c = get_citation_from_row(row_as_hash)

  t = get_treatment_for_citation_and_row(c, row_as_hash)

  statement = "START TRANSACTION;\n"

  date = row_as_hash["date"].nil? ? "DEFAULT" : "'#{row_as_hash["date"]}'"
  dateloc = row_as_hash["dateloc"].nil? ? "DEFAULT" : row_as_hash["dateloc"]
  mgmttype = "'#{row_as_hash["mgmttype"]}'"
  level = row_as_hash["level"].nil? ? "DEFAULT" : row_as_hash["level"]
  units = row_as_hash["units"].nil? ? "DEFAULT" : "'#{row_as_hash["units"]}'"
  notes = row_as_hash["notes"].nil? ? "DEFAULT" : "'#{row_as_hash["notes"]}'"

  statement += sprintf(MANAGEMENT_INSERT_TEMPLATE,
                       c.id,
                       date,
                       dateloc,
                       mgmttype,
                       level,
                       units,
                       notes,
                       @user_id)
  statement += sprintf(MANAGEMENTS_TREATMENTS_INSERT_TEMPLATE, t.id)

  statement += "COMMIT;\n"

end



# main

# Parse command line

require 'trollop'
opts = Trollop::options do
  #version "..."
  banner <<-EOS
=====================
insert_managements.rb
=====================

Usage:
       insert_managements [options] <CSV input file>
where [options] are:
EOS
  opt :login, "The Rails login for the user running the script (required)", type: String, short: "-u"
  opt :output, "Output file", type: String, default: "new_managements.sql", short: "-o"
  opt :environment, "Rails environment to run in", type: String, default: "development", short: "-e"
  opt :man, "Show complete usage instuctions"
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


Trollop::die :login, "must be specified" if opts[:login].nil?
Trollop::die "You must specify an input file" if ARGV.empty?
Trollop::die "Too many command line arguments" if ARGV.size > 1
csvpath = ARGV[0]
Trollop::die "File \"#{csvpath}\" does not exist" unless File.exist?(csvpath)

# Load Rails

APP_PATH = File.expand_path('../../config/application',  __FILE__)
require File.expand_path('../../config/boot',  __FILE__)
require APP_PATH

Rails.env = opts[:environment]

Rails.application.require_environment!


# More options validation

user = User.find_by_login(opts[:login])
Trollop::die :login, "must be a valid Rails login for the #{Rails.env} environment" if user.nil?
@user_id = user.id






csv = CSV.open(csvpath, { headers: true })

csv.readline # need to read first line to get headers
headings = csv.headers

if !(REQUIRED_HEADINGS - headings).empty?
  puts "ERROR: Your CSV file must contain the following columns (in any order): 'citation_author', 'citation_title', 'citation_year', 'treatment_name', 'mgmttype', 'level', 'units', 'date'"
  exit 1
end

ignored_headings = headings - RECOGNIZED_HEADINGS
if !(ignored_headings).empty?
  puts "WARNING: The columns with these headings will be ignored: #{ignored_headings}"
end

f = File.new(opts[:output], "w")

csv.each do |row|

  begin

    f.puts csvrow_to_input_statements(row.to_hash)

  rescue => e

    puts e.message

    next

  end

end
