class Workflow < ActiveRecord::Base

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{  }
  SEARCH_FIELDS = %w{ workflows.outdir workflows.started_at workflows.finished_at workflows.created_at workflows.updated_at }

  scope :order, lambda { |order| {:order => order, :include => SEARCH_INCLUDES } }
  scope :search, lambda { |search| {:conditions => simple_search(search) } }

  comma do
    id
    outdir
    started_at
    finished_at
    created_at
    updated_at
  end

  def to_s(format=nil)
    case format
    when :long
      "#{outdir} #{started_at} #{finished_at}"
    else
      outdir
    end
  end
  # Used in forms to unify fields show in select boxes across site.
  def select_default
    "#{id}: #{self}"
  end
  
  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    ["workflows.id", "workflows.outdir"]
  end

end
