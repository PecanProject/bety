class Run < ActiveRecord::Base

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ model site }
  SEARCH_FIELDS = %w{ models.model_name sites.sitename runs.start_time runs.finish_time runs.started_at runs.finished_at runs.outdir runs.outprefix runs.setting runs.parameter_list }

  validates_format_of :start_date, :with => /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/, :allow_blank => true, :message => 'Must be in format using UTC: YYYY-MM-DD HH:MM:SS' 
  validates_format_of :end_date, :with => /\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}/, :allow_blank => true, :message => 'Must be in format using UTC: YYYY-MM-DD HH:MM:SS' 
  has_and_belongs_to_many :posteriors
  has_and_belongs_to_many :inputs
  has_many :likelihoods
  belongs_to :model
  belongs_to :site
  belongs_to :ensemble

  validates_presence_of     :model_id
  validates_presence_of     :site_id
  validates_presence_of     :outdir

  named_scope :order, lambda { |order| {:order => order, :include => SEARCH_INCLUDES } }
  named_scope :search, lambda { |search| {:conditions => simple_search(search) } } 

  comma do
    id
    model_id
    site_id
    start_time
    finish_time
    outdir
    outprefix
    setting
    parameter_list
    created_at
    updated_at
  end

  def model_site
    "#{model} #{site}"
  end
  def to_s
    model_site
  end
  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["runs.id"]
  end
end
