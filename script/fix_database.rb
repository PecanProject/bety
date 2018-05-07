#!/usr/bin/env ruby

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
require_relative 'enhanced_connection'

con = EnhancedConnection.new

con.generate_sql_fix_statements
