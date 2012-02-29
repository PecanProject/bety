class Run < ActiveRecord::Base
  has_and_belongs_to_many :posteriors
  has_and_belongs_to_many :inputs
  has_many :likelihoods
  belongs_to :model
  belongs_to :site
  belongs_to :ensemble

  validates_presence_of     :model_id
  validates_presence_of     :site_id
  validates_presence_of     :outdir
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
