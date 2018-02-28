class Posterior < ActiveRecord::Base

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ pft }
  SEARCH_FIELDS = %w{ pfts.name }

  has_many :posteriors_ensembles, :class_name => "PosteriorsEnsembles"
  has_many :ensembles, :through => :posteriors_ensembles

  has_many :posterior_samples, :class_name => "PosteriorSamples"
  
  has_many :files, :as => :container, :class_name => 'DBFile'

  belongs_to :pft
  belongs_to :format

  validates_presence_of     :pft_id

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES).references(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  comma do
    id
    pft_id
    created_at
    updated_at
  end
  def pft_createdat
    "#{pft} #{created_at.to_s(:db)}"
  end
  def to_s
    pft_createdat
  end
  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["posteriors.id", "posteriors.created_at"]
  end
end
