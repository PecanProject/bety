class AddModelTypeToPfts < ActiveRecord::Migration

  class Pfts < ActiveRecord::Base; end

  def self.up
    add_column :pfts, :model_type, :string

    Pfts.update_all("model_type = 'SIPNET', name=substring(name, 8)", "name like 'sipnet.%'")
    Pfts.update_all("model_type = 'BIOCRO', name=substring(name, 8)", "name like 'biocro.%'")
    Pfts.update_all("model_type = 'ED2'", "model_type IS NULL")
  end

  def self.down
    Pfts.update_all("name=concat('sipnet.', name)", "model_type = 'SIPNET'")
    Pfts.update_all("name=concat('biocro.', name)", "model_type = 'BIOCRO'")

    remove_column :pfts, :model_type
  end
end
