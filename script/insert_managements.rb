#!/usr/bin/env ruby


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

MANAGEMENT_INSERT_TEMPLATE = <<SQL
INSERT INTO managements (citation_id, date, dateloc, mgmttype, level, units, notes, user_id)
                 VALUES (     %i,      %s,    %s,      %s,       %s,    %s,    %s,     %i  );
SQL

MANAGEMENTS_TREATMENTS_INSERT_TEMPLATE = <<SQL
INSERT INTO managements_treatments (treatment_id, management_id)
                            VALUES (      %i,       LASTVAL()  );
SQL

def csvrow_to_input_statements(row_as_hash)

  c = get_citation_from_row(row_as_hash)

  t = get_treatment_for_citation_and_row(c, row_as_hash)

  statement = "START TRANSACTION;\n"

  date = row_as_hash["date"].nil? ? "DEFAULT" : "'#{row_as_hash["date"]}'"
  dateloc = row_as_hash["dateloc"].nil? ? "DEFAULT" : "'#{row_as_hash["dateloc"]}'"
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


# Parse command line

require 'trollop'
opts = Trollop::options do
  #version "..."
  banner <<-EOS

Usage:
       insert_managements [options] <CSV input file>
where [options] are:
EOS
  opt :login, "The Rails login for the user running the script (required)", type: String, short: "-u"
  opt :output, "Output file", type: String, default: "new_managements.sql", short: "-o"
  opt :environment, "Rails environment to run in", type: String, default: "development", short: "-e"
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

REQUIRED_HEADINGS = ['citation_author', 'citation_title', 'citation_year', 'treatment_name', 'mgmttype']
OPTIONAL_HEADINGS = [ 'date', 'dateloc', 'level', 'units', 'notes' ]
RECOGNIZED_HEADINGS = REQUIRED_HEADINGS + OPTIONAL_HEADINGS

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




