class Likelihood < ActiveRecord::Base

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ input run variable }
  SEARCH_FIELDS = %w{ variables.name likelihoods.loglikelihood likelihoods.n_eff likelihoods.weight likelihoods.residual }


  belongs_to :run
  belongs_to :variable
  belongs_to :input

  validates_presence_of     :run_id
  validates_presence_of     :variable_id
  validates_presence_of     :loglikelihood

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  comma do
    id
    run_id
    variable_id
    input_id
    loglikelihood
    n_eff
    weight
    residual
    created_at
    updated_at
  end
  
  def variable_site_runid
    "#{variable} #{site} #{run_id}"
  end

  def to_s
    variable_site_runid
  end

  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["likelihoods.id", "likelihoods.run_id"]
  end
end
