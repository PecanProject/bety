class AddModelTypeTable < ActiveRecord::Migration
  def self.up
    create_table :modeltypes do |t|
      t.string :name, :unique => true, :null => false
      t.integer :user_id
      t.datetime :created_at
      t.datetime :updated_at
    end
    add_index :modeltypes, [:name], :unique => true

    execute("insert into modeltypes(name) (select distinct coalesce(model_type, model_name) from models);")

    add_column :models, :modeltype_id, :integer, :limit => 8
    execute("update models set modeltype_id=(select id from modeltypes where modeltypes.name=coalesce(model_type, model_name));")
    change_column :models, :modeltype_id, :integer, :limit => 8, :null => false

    add_column :pfts, :modeltype_id, :integer, :limit => 8
    execute("update pfts set modeltype_id=(select id from modeltypes where modeltypes.name=pfts.model_type);")
    change_column :pfts, :modeltype_id, :integer, :limit => 8, :null => false

    remove_column :models, :model_type
    remove_column :pfts, :model_type

    create_table :modeltypes_formats do |t|
      t.integer :modeltype_id, :limit => 8, :null => false
      t.string :tag, :null => false
      t.integer :format_id, :limit => 8, :null => false
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
    execute("update models set model_type=(select name from modeltypes where modeltypes.id=models.modeltype_id);")
    remove_column :models, :modeltype_id

    add_column :pfts, :model_type, :string
    execute("update pfts set model_type=(select name from modeltypes where modeltypes.id=pfts.modeltype_id);")
    remove_column :pfts, :modeltype_id

    drop_table :modeltypes
  end
end
