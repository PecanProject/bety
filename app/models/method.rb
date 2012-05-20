class Methods < ActiveRecord::Base
  extend SimpleSearch
  SEARCH_INCLUDES = %w{ citation }
  SEARCH_FIELDS = %w{ methods.name methods.description citations.author }

  belongs_to :citation
  has_many :traits
  has_many :yields

  named_scope :order, lambda { |order| {:order => order, :include => SEARCH_INCLUDES } }
  named_scope :search, lambda { |search| {:conditions => simple_search(search) } } 
end
