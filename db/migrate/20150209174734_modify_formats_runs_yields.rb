class ModifyFormatsRunsYields < ActiveRecord::Migration
  def self.up
    add_column :formats, :mimetype_id, :integer, :limit => 8
    execute('UPDATE formats SET mimetype_id = (SELECT id FROM mimetypes WHERE type_string = mime_type);')
    remove_column :formats, :mime_type

    add_column :yields, :entity_id, :integer, :limit => 8
    add_column :yields, :date_year, :integer
    add_column :yields, :date_month, :integer
    add_column :yields, :date_day, :integer

    remove_column :runs, :start_date
    remove_column :runs, :end_date

    drop_table :inputs_variables
    drop_table :location_yields
    drop_table :counties
  end

  def self.down

  	create_table "location_yields", :force => true do |t|
  	  t.decimal  "yield",      :precision => 20, :scale => 15
  	  t.string   "species"
  	  t.datetime "created_at"
  	  t.datetime "updated_at"
  	  t.integer  "county_id"
  	end

  	add_index "location_yields", ["county_id"], :name => "index_location_yields_on_county_id"
  	add_index "location_yields", ["species", "county_id"], :name => "index_location_yields_on_species_and_county_id"
  	add_index "location_yields", ["species"], :name => "index_location_yields_on_location_and_species"
  	add_index "location_yields", ["yield"], :name => "index_location_yields_on_yield"



  	create_table "inputs_variables", :force => true do |t|
  	  t.integer  "input_id", :limit => 8
  	  t.integer  "variable_id", :limit => 8
  	  t.datetime "created_at"
  	  t.datetime "updated_at"
  	end

  	add_index "inputs_variables", ["input_id", "variable_id"], :name => "index_inputs_variables_on_input_id_and_variable_id", :unique => true



  	create_table "counties", :force => true do |t|
  	  t.string   "name"
  	  t.datetime "created_at"
  	  t.datetime "updated_at"
  	  t.string   "state"
  	  t.integer  "state_fips"
  	  t.integer  "county_fips"
  	end


    execute %q{
ALTER TABLE "location_yields" ADD CONSTRAINT "fk_location_yields_counties_1" FOREIGN KEY ("county_id") REFERENCES "counties" ("id");
ALTER TABLE "inputs_variables" ADD CONSTRAINT "fk_inputs_variables_inputs_1" FOREIGN KEY ("input_id") REFERENCES "inputs" ("id") ON DELETE CASCADE;
ALTER TABLE "inputs_variables" ADD CONSTRAINT "fk_inputs_variables_variables_1" FOREIGN KEY ("variable_id") REFERENCES "variables" ("id") ON DELETE CASCADE;
}




    add_column :runs, :end_date, :string
    add_column :runs, :start_date, :string


    remove_column :yields, :date_day
    remove_column :yields, :date_month
    remove_column :yields, :date_year
    remove_column :yields, :entity_id
 

    add_column :formats, :mime_type, :string
    execute('UPDATE formats SET mime_type = (SELECT type_string FROM mimetypes mt WHERE mt.id = mimetype_id);')
    remove_column :formats, :mimetype_id
 end
end
