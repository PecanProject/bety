class Specie < ActiveRecord::Base
  require "comma"
  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ species.scientificname species.commonname }

  has_many :pfts_species, :class_name => "PftsSpecies"
  has_many :pfts, :through => :pfts_species

  has_many :yields
  has_many :traits
  has_many :cultivars

  scope :all_order, order('genus, species')
  scope :by_letter, lambda { |letter| where('genus like ?', letter + "%") }
  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }
=begin
do json / xml api fields to return
genus
species
scientificname
=end
  comma do |f|
    f.id
    f.genus
    f.species
    f.scientificname
    f.commonname
    f.notes
    f.created_at
    f.updated_at
  end


  def genus_species
    !self.scientificname.blank? ? scientificname : "#{genus} #{species}"
  end
 
  def symbol_name
    "#{AcceptedSymbol} - #{scientificname}"
  end

  def to_s
    genus_species
  end

  def select_default
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["species.id", "species.scientificname", "species.genus", "species.species"]
  end
end
