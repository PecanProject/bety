class Entity < ActiveRecord::Base

  include Overrides

  belongs_to :parent, :class_name => "Entity"
  has_many :children, :foreign_key => "parent_id", :class_name => "Entity"
  has_many :traits

  # Validation callbacks

  before_validation WhitespaceNormalizer.new([:name])

  def to_s
    name
  end
  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["entities.id", "entities.name"]
  end
end
