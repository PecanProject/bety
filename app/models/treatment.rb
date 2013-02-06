class Treatment < ActiveRecord::Base

  include Overrides

  has_many :traits
  has_many :yields

  has_many :managements_treatments, :class_name => "ManagementsTreatments"
  has_many :managements, :through => :managements_treatments

  has_many :citations_treatments, :class_name => "CitationsTreatments"
  has_many :citations, :through => :citations_treatments

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
