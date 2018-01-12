# -*- coding: utf-8 -*-
class Specie < ActiveRecord::Base
  require "comma"
  include Overrides

  def as_json(options = {})
    options[:except] = self.class.column_names.select { |nam| nam =~ /[A-Z]/ && nam != "AcceptedSymbol" }
    super(options)
  end

  def to_xml(options = {})
    options[:except] = self.class.column_names.select { |nam| nam =~ /[A-Z]/ && nam != "AcceptedSymbol" }
    super(options)
  end

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ species.scientificname species.commonname }

  has_many :pfts_species, :class_name => "PftsSpecies"
  has_many :pfts, :through => :pfts_species

  has_many :yields
  has_many :traits
  has_many :cultivars


  # VALIDATION

  ## Validation methods

  def scientificname_includes_genus_and_species
    if scientificname !~ /\A#{genus}.*#{species}\z/
      errors.add(:scientificname, "must contain the genus and species")
    end
  end

  ## Validation callbacks

  before_validation WhitespaceNormalizer.new([:commonname, :scientificname, :genus, :species])

  #### Note: normalization of the hybrid symbol (x -> ×) is handled by a database trigger function.

  ## Validations

  validates_numericality_of :spcd,
      { only_integer: true,
        greater_than_or_equal_to: 0,
        less_than_or_equal_to: 10000,
        allow_blank: true }
  validates_format_of :genus,
      { with: /\A([A-Z][-a-z]*)?\z/,
       message: "must begin with a capital letter and contain only letters and hyphens" }
  validates_format_of :species,
      { with: /\A(([A-Z]\.|[a-zA-Z]{2,}\.?|&|\u00d7|x)( |-|\z))*\z/,
        message: <<TEXT
should be zero or more space-or-hyphen-separated groups of capital
letters followed by a period, sequences of two or more letters possibly
followed by a period, ampersands, and times symbols.
TEXT
      }
  validates :scientificname,
      presence: true,
      format: { with: /\A[A-Z][-a-z]*( .*)?\z/,
                message: 'must begin with a capital letter' }

  # This validation may prevent updating some existing rows unless the genus,
  # species, and scientificname are changed to be consistent.
  validate :scientificname_includes_genus_and_species



  scope :all_order, -> { order('genus, species') }
  scope :by_letter, lambda { |letter| where('genus like ?', letter + "%") }
  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  comma do |f|
    f.id
    f.spcd
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
