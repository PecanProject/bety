class Cultivar < ActiveRecord::Base
  has_many :traits
  has_many :yields

  belongs_to :specie

  comma do
    id
    specie_id
    name
    ecotype
    notes
    created_at
    updated_at
    previous_id
  end

  def sn_name
    "#{specie} #{name}"
  end
  def to_s
    sn_name
  end
  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["cultivars.name"]
  end
end
