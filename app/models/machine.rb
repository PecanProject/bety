class Machine < ActiveRecord::Base
  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ machines.hostname } 

  scope :order, lambda { |order| {:order => order, :include => SEARCH_INCLUDES } }
  scope :search, lambda { |search| {:conditions => simple_search(search) } }

  has_many :bety_files

  def select_default
    self.to_s
  end

  def to_s
    hostname
  end

end
