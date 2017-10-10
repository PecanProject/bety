module Utilities::SQLComments

  def self.get_column_comment(table_name, column_name)

    query = <<-QUERY
      SELECT d.description FROM pg_description d
        JOIN information_schema.columns c
          ON (c.table_schema = current_schema
              AND (current_schema || '.' || c.table_name)::regclass =
                   d.objoid AND c.ordinal_position = d.objsubid)
        WHERE c.table_name = '#{table_name}' AND c.column_name = '#{column_name}'
      QUERY

    ActiveRecord::Base.connection.select_value(query)

  end

  def self.get_table_description(table_name)

    query = <<-QUERY
      SELECT obj_description('#{table_name}'::regclass, 'pg_class');
    QUERY

    ActiveRecord::Base.connection.select_value(query)

  end

end
