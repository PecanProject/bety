class Variable < ActiveRecord::Base
  has_many :covariates
  has_many :traits, :through => :covariates
  has_many :priors
  has_many :likelihoods
  has_many :traits
  has_and_belongs_to_many :inputs

  named_scope :all_order, :order => 'name'  

  comma do
    id
    description
    units
    notes
    created_at
    updated_at
    name
  end

  def name_units
    "#{name} - #{units}"
  end
  def to_s
    name_units
  end
  def select_default
    "#{id}: #{self}"
  end


  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["variables.id", "variables.name", "variables.units"]
  end
end
