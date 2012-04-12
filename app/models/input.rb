class Input < ActiveRecord::Base
  has_and_belongs_to_many :runs
  has_and_belongs_to_many :variables
  has_many :likelihoods
  has_one :input_file
  belongs_to :site
  belongs_to :user


  # No longer
  #belongs_to :format

  #Self reference
  has_many :children, :class_name => "Input"
  belongs_to :parent, :class_name => "Input", :foreign_key => "parent_id"


#  accepts_nested_attributes_for :format,
#    :reject_if => proc { |format| format['mime_type'].blank? }
  accepts_nested_attributes_for :site


  validates_presence_of     :site_id
#  validates_presence_of     :format_id
#  validates_presence_of     :filepath

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


  def all_files
    InputFile.all(:conditions => ["file_id = ?",file_id])
  end

end
