class Ensemble < ActiveRecord::Base

  has_many :runs

  comma do
    id
    notes
    created_at
    updated_at
  end

  def to_s
    notes[0..20]
  end
  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["ensembles.id", "ensembles.notes"]
  end

end
