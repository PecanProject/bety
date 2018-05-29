#!/usr/bin/env ruby

# This script attempts to find missing foreign-key constraints by finding column
# names of the form "xxx_id" and checking to see if there is an existing
# corresponding foreign-key constraint.

require_relative 'lib/enhanced_connection'

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

