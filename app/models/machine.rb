class Machine < ActiveRecord::Base
  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ machines.hostname }

  validates :hostname,
      presence: true,
      uniqueness: true

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  has_many :files, :class_name => 'DBFile'

  def select_default
    self.to_s
  end

  def to_s
    hostname
  end

end
