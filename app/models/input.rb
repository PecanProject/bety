class Input < ActiveRecord::Base
  has_and_belongs_to_many :runs
  has_and_belongs_to_many :variables
  has_many :likelihoods
  belongs_to :site
  belongs_to :format
  belongs_to :raw
  accepts_nested_attributes_for :format,
    :reject_if => proc { |format| format['mime_type'].blank? }
  accepts_nested_attributes_for :site


  validates_presence_of     :site_id
  validates_presence_of     :format_id
  validates_presence_of     :filepath

  comma do
    id
    site_id
    filepath
    name
    format
    original_data
    notes
    start_date
    end_date
    created_at
    updated_at
  end

  def to_s
    "#{name} #{site}"
  end
  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["inputs.id"]
  end
end
