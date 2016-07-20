class Ensemble < ActiveRecord::Base

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ ensembles.runtype ensembles.notes ensembles.created_at ensembles.updated_at }

  RUNTYPETYPES = ["ENS","SA"]

  has_many :runs
  has_many :posteriors_ensembles, :class_name => "PosteriorsEnsembles"
  has_many :posteriors, :through => :posteriors_ensembles

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  validates_inclusion_of :runtype, :in => RUNTYPETYPES, :allow_blank => true

  comma do
    id
    notes
    created_at
    updated_at
  end


  def to_s
    (notes || '')[0..20]
  end
  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["ensembles.id", "ensembles.notes"]
  end

end
