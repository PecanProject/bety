class Variable < ActiveRecord::Base
  # Using "attr_protected []" doesn't remove protection for the "type" column,
  # so we have to whitelist accessible columns instead:
  attr_accessible :description, :units, :notes, :name, :standard_name, :standard_units, :label, :type

  # rename inheritance column from "type" so we can have "type" as the name of
  # an attribute:
  self.inheritance_column = 'zoink'

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ variables.name variables.description variables.units variables.notes }

  has_many :covariates
  has_many :traits, :through => :covariates
  has_many :formats_variables
  has_many :formats, :through => :formats_variables
  has_many :priors
  has_many :likelihoods
  has_many :traits

  # VALIDATION

  ## Validation callbacks

  before_validation WhitespaceNormalizer.new([:description, :units, :name])


  scope :all_order, -> { order('name') }
  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

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

  def autocomplete_label
    "#{name} (#{units}) #{description.blank? ? "(no description)" : "- #{description}"}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["variables.id", "variables.name", "variables.units"]
  end
end
