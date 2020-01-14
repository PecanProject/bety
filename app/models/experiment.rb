class Experiment < ActiveRecord::Base
  attr_protected []

  extend SimpleSearch

  SEARCH_INCLUDES = %w{ user }
  SEARCH_FIELDS = %w{ experiments.name users.name }

  before_validation WhitespaceNormalizer.new([:name])
  validates_presence_of :name

  has_many :experiments_sites
  has_many :sites, :through => :experiments_sites

  belongs_to :user
  
  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES).references(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

end
