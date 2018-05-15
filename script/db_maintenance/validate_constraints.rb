#!/usr/bin/env ruby
# coding: utf-8

# This script attempts to validate all existing CHECK and FOREIGN KEY
# constraints and prints out the results of the attempt.

require_relative 'enhanced_connection'

ConstraintQuery = <<FK
SELECT
    constraint_name, table_name
FROM 
    information_schema.table_constraints
WHERE constraint_type IN ('FOREIGN KEY', 'CHECK') AND
      table_schema = 'public' AND
      constraint_schema = 'public' AND
      constraint_name IN (SELECT constraint_name FROM information_schema.constraint_column_usage);
FK


con = EnhancedConnection.new

con.send_query(ConstraintQuery)

result = con.get_result

constraint_list = result.to_a

constraint_list.each do |row|
  validation_statement = sprintf("ALTER TABLE \"%s\" VALIDATE CONSTRAINT \"%s\";", row["table_name"], row["constraint_name"])
  begin
    con.exec(validation_statement)
    printf("✓ Successfully validated constraint %s.\n", row["constraint_name"])
  rescue => e
    puts "✗ " + e.to_s
  end
end

