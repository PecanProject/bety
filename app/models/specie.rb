class Specie < ActiveRecord::Base
  require "comma"
  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ species.scientificname species.commonname }

  has_and_belongs_to_many :pfts

  has_many :yields
  has_many :traits
  has_many :cultivars

  scope :all_order, order('genus, species')
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
    f.AcceptedSymbol
    f.SynonymSymbol
    f.Symbol
    f.PLANTS_Floristic_Area
    f.State
    f.Category
    f.Family
    f.FamilySymbol
    f.FamilyCommonName
    f.xOrder
    f.SubClass
    f.Class
    f.SubDivision
    f.Division
    f.SuperDivision
    f.SubKingdom
    f.Kingdom
    f.ITIS_TSN
    f.Duration
    f.GrowthHabit
    f.NativeStatus
    f.NationalWetlandIndicatorStatus
    f.RegionalWetlandIndicatorStatus
    f.ActiveGrowthPeriod
    f.AfterHarvestRegrowthRate
    f.Bloat
    f.C2N_Ratio
    f.CoppicePotential
    f.FallConspicuous
    f.FireResistance
    f.FoliageTexture
    f.GrowthForm
    f.GrowthRate
    f.MaxHeight20Yrs
    f.MatureHeight
    f.KnownAllelopath
    f.LeafRetention
    f.Lifespan
    f.LowGrowingGrass
    f.NitrogenFixation
    f.ResproutAbility
    f.AdaptedCoarseSoils
    f.AdaptedMediumSoils
    f.AdaptedFineSoils
    f.AnaerobicTolerance
    f.CaCO3Tolerance
    f.ColdStratification
    f.DroughtTolerance
    f.FertilityRequirement
    f.FireTolerance
    f.MinFrostFreeDays
    f.HedgeTolerance
    f.MoistureUse
    f.pH_Minimum
    f.pH_Maximum
    f.Min_PlantingDensity
    f.Max_PlantingDensity
    f.Precipitation_Minimum
    f.Precipitation_Maximum
    f.RootDepthMinimum
    f.SalinityTolerance
    f.ShadeTolerance
    f.TemperatureMinimum
    f.BloomPeriod
    f.CommercialAvailability
    f.FruitSeedPeriodBegin
    f.FruitSeedPeriodEnd
    f.Propogated_by_BareRoot
    f.Propogated_by_Bulbs
    f.Propogated_by_Container
    f.Propogated_by_Corms
    f.Propogated_by_Cuttings
    f.Propogated_by_Seed
    f.Propogated_by_Sod
    f.Propogated_by_Sprigs
    f.Propogated_by_Tubers
    f.Seeds_per_Pound
    f.SeedSpreadRate
    f.SeedlingVigor
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
