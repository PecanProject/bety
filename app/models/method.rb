class Methods < ActiveRecord::Base
  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ citation }
  SEARCH_FIELDS = %w{ methods.name methods.description citations.author }

  belongs_to :citation
  has_many :traits
  has_many :yields

  named_scope :order, lambda { |order| {:order => order, :include => SEARCH_INCLUDES } }
  named_scope :search, lambda { |search| {:conditions => simple_search(search) } }

  def to_s
    "#{name}: #{description[0..20]}"
  end


  def select_default
    "#{id}: #{self}"
  end 
end
