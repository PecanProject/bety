class Format < ActiveRecord::Base

  has_many :inputs

  comma do
    id
    name
    mime_type
    dataformat 
    notes
    created_at
    updated_at
  end

  def name_mimetype
    "#{name} #{mime_type}"
  end
  def to_s
    name_mimetype
  end
  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["formats.id", "formats.name", "formats.mime_type"]
  end
end
