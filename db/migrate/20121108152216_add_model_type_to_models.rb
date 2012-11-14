class AddModelTypeToModels < ActiveRecord::Migration

  class Models < ActiveRecord::Base; end

  def self.up
    add_column :models, :model_type, :string
    
    Model.update_all("model_type = 'ED2'", "model_name like 'ed%'")
    Model.update_all("model_type = 'SIPNET'", "model_name like 'sipnet%'")

    Models.update_all("model_type = 'ED2'", "model_name like 'ed%'")
    Models.update_all("model_type = 'SIPNET'", "model_name like 'sipnet%'")
    Models.update_all("model_type = 'BIOCRO'", "model_name like 'biocro%'")
    
  end

  def self.down
   remove_column :models, :model_type
  end
end
