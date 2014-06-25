class Prior < ActiveRecord::Base

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ citation variable }
  SEARCH_FIELDS = %w{ citations.author variables.name priors.phylogeny priors.distn priors.parama priors.paramb priors.n priors.notes }

  has_many :pfts_priors, :class_name => "PftsPriors"
  has_many :pfts, :through => :pfts_priors

  belongs_to :variable
  belongs_to :citation

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  comma do
    id
    citation_id
    variable_id
    phylogeny
    distn
    parama
    paramb
    paramc
    n
    notes
    created_at
    updated_at
  end

  def var_cit
    "#{variable.try(:description)} - #{citation} - #{phylogeny}"
  end
  def varname_cit
    "#{variable} - #{citation} - #{phylogeny}"
  end
  def id_var_name_cit
    "#{id.to_s} : #{var_cit}"
  end
  def to_s
    varname_cit
  end
  def select_default
    "#{id} : #{self}"
  end
  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["priors.id", "priors.phylogeny"]
  end
end
