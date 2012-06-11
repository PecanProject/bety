class Management < ActiveRecord::Base
  extend SimpleSearch
  SEARCH_INCLUDES = %w{ citation }
  SEARCH_FIELDS = %w{ citations.author managements.date managements.mgmttype managements.level managements.units managements.notes }

  has_and_belongs_to_many :treatments

  belongs_to :citation
  belongs_to :user

  named_scope :order, lambda { |order| {:order => order, :include => SEARCH_INCLUDES } }
  named_scope :search, lambda { |search| {:conditions => simple_search(search) } } 

  comma do
    id
    citation_id
    date
    dateloc
    mgmttype
    level
    units
    notes
    created_at
    updated_at
  end

  def self.management_types
    [ 'burned', 'coppice', 'cultivated', 'cultivated or grazed', 'fertilization_Ca', 'fertilization_K', 'fertilization_N', 'fertilization_P', 'fertilization_other', 'fungicide', 'grazed', 'harvest', 'herbicide', 'irrigation', 'light', 'pesticide', 'planting (plants / m2)', 'row spacing', 'seeding', 'tillage','warming_soil','warming_air','initiation of natural succession','major storm','root exclusion', 'trenching', 'CO2 fumigation', 'soil disturbance']
  end

  def date_type_level
    "#{date} - #{type} : #{level}"
  end
  def to_s
    date_type_level
  end
  def select_default
    "#{id}: #{self}"
  end
  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["managements.id", "managements.date", "managements.type", "managements.level"]
  end
end
