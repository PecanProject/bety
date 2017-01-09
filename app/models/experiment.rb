class Experiment < ActiveRecord::Base

  extend SimpleSearch

  SEARCH_INCLUDES = %w{ user }
  SEARCH_FIELDS = %w{ experiments.name users.name }

  belongs_to :user
  
  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

end
