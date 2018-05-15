#!/usr/bin/env ruby

# This script attempts to find missing foreign-key constraints by finding column
# names of the form "xxx_id" and checking to see if there is an existing
# corresponding foreign-key constraint.

require_relative 'enhanced_connection'

FkQuery = <<FK
SELECT
    tc.constraint_name, tc.table_name, kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM 
    information_schema.table_constraints AS tc 
    JOIN information_schema.key_column_usage AS kcu
      ON tc.constraint_name = kcu.constraint_name
    JOIN information_schema.constraint_column_usage AS ccu
      ON ccu.constraint_name = tc.constraint_name
WHERE constraint_type = 'FOREIGN KEY'
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
  if ['container_id',
      'created_user_id',
      'updated_user_id',
      'previous_id',
      'sync_host_id',
      'session_id'].include? column_name
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
    puts "constraint for #{table_name}.#{column_name} not found"
  end
  
end

