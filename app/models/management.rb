class Management < ActiveRecord::Base
  has_and_belongs_to_many :treatments

  belongs_to :citation
  belongs_to :user

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
