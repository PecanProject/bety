class Pft < ActiveRecord::Base
  has_and_belongs_to_many :priors
  has_and_belongs_to_many :specie
  has_many :posteriors

  comma do
    id
    definition
    created_at
    updated_at
    name
  end

  def name_definition
    "#{name} #{definition[0..19]}"
  end
  def to_s
    name_definition
  end
  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["pfts.id", "pfts.name", "pfts.definition"]
  end
end
