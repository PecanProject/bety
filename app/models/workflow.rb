class Workflow < ActiveRecord::Base

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{  }
  SEARCH_FIELDS = %w{ workflows.folder workflows.started_at workflows.finished_at workflows.created_at workflows.updated_at }

  has_many :ensembles
  belongs_to :model
  belongs_to :site
  belongs_to :user

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  comma do
    id
    folder
    started_at
    finished_at
    created_at
    updated_at
    notes
  end

  def to_s(format=nil)
    case format
    when :long
      "#{folder} #{started_at} #{finished_at}"
    else
      folder
    end
  end
  # Used in forms to unify fields show in select boxes across site.
  def select_default
    "#{id}: #{self}"
  end
  
  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    ["workflows.id", "workflows.folder"]
  end

end
