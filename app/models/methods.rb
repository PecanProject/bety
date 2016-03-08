class Methods < ActiveRecord::Base
  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ citation }
  SEARCH_FIELDS = %w{ methods.name methods.description citations.author }

  belongs_to :citation
  has_many :traits, foreign_key: :method_id
  has_many :yields, foreign_key: :method_id

  # VALIDATION

  ## Validation callbacks

  before_validation WhitespaceNormalizer.new([:name])



  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  def to_s
    "#{name}: #{description[0..20]}"
  end


  def select_default
    "#{id}: #{self}"
  end 
end
