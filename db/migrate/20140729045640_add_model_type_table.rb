class AddModelTypeTable < ActiveRecord::Migration
  class Models < ActiveRecord::Base; end

  def self.up
    create_table :modeltypes do |t|
      t.string :model_type, :unique => true
      t.integer :user_id
      t.datetime :created_at
      t.datetime :updated_at
    end
    add_index :modeltypes, [:model_type], :unique => true

    Models.update_all("model_type = 'UNKNOWN'", "model_type IS NULL or model_type=''")
    execute("insert into modeltypes(model_type) (select distinct model_type from models);")

    add_column :models, :modeltype_id, :integer, :limit => 8
    execute("update models set modeltype_id=(select id from modeltypes where modeltypes.model_type=models.model_type);")

    add_column :pfts, :modeltype_id, :integer, :limit => 8
    execute("update pfts set modeltype_id=(select id from modeltypes where modeltypes.model_type=pfts.model_type);")

    remove_column :models, :model_type
    remove_column :pfts, :model_type

    create_table :modeltypes_formats do |t|
      t.integer :modeltype_id, :limit => 8
      t.string :tag
      t.integer :format_id, :limit => 8
      t.boolean :required, :default => false
      t.boolean :input, :default => true # true=input, false=output
      t.integer :user_id
      t.datetime :created_at
      t.datetime :updated_at
    end
    add_index :modeltypes_formats, [:modeltype_id, :tag], :unique => true
    add_index :modeltypes_formats, [:modeltype_id, :format_id, :input], :name => "index_modeltypes_formats_on_modeltype_id_format_id_input", :unique => true

  end

  def self.down
    drop_table :modeltypes_formats

    add_column :models, :model_type, :string
    execute("update models set model_type=(select model_type from modeltypes where modeltypes.id=models.modeltype_id);")
    remove_column :models, :modeltype_id

    add_column :pfts, :model_type, :string
    execute("update pfts set model_type=(select model_type from modeltypes where modeltypes.id=pfts.modeltype_id);")
    remove_column :pfts, :modeltype_id

    drop_table :modeltypes
  end
end
