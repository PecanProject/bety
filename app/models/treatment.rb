class Treatment < ActiveRecord::Base

  include Overrides

  has_many :traits
  has_many :yields

  has_and_belongs_to_many :managements
  has_and_belongs_to_many :citations

  belongs_to :user

  comma do
    id
    name
    definition
    created_at
    updated_at
    control
  end

  def name_definition
    "#{name} : #{(definition || "NA")[0..19]}"
  end
  def name_definition_w_citation
    "#{name_definition} - #{citations.collect(&:author_year).join(',')}"
  end
  def to_s 
    name_definition_w_citation
  end
  def select_default 
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["treatments.id", "treatments.name", "treatments.definition"]
  end

end
