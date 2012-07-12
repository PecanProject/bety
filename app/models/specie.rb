class Specie < ActiveRecord::Base

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ species.AcceptedSymbol species.scientificname species.commonname }

  has_and_belongs_to_many :pfts

  has_many :yields
  has_many :traits
  has_many :cultivars

  named_scope :all_order, :order => 'genus, species'

  named_scope :by_letter, lambda { |letter| { :conditions => ['genus like ?', letter + "%"] } }
  named_scope :order, lambda { |order| {:order => order, :include => SEARCH_INCLUDES } }
  named_scope :search, lambda { |search| {:conditions => simple_search(search) } } 

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
    f.FederalNoxiousStatus
    f.FederalNoxiousCommonName
    f.StateNoxiousStatus
    f.StateNoxiousCommonName
    f.Invasive
    f.Federal_TE_Status
    f.State_TE_Status
    f.State_TE_Common_Name
    f.NationalWetlandIndicatorStatus
    f.RegionalWetlandIndicatorStatus
    f.ActiveGrowthPeriod
    f.AfterHarvestRegrowthRate
    f.Bloat
    f.C2N_Ratio
    f.CoppicePotential
    f.FallConspicuous
    f.FireResistance
    f.FlowerColor
    f.FlowerConspicuous
    f.FoliageColor
    f.FoliagePorositySummer
    f.FoliagePorosityWinter
    f.FoliageTexture
    f.FruitColor
    f.FruitConspicuous
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
    f.Shape_and_Orientation
    f.Toxicity
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
    f.FruitSeedAbundance
    f.FruitSeedPeriodBegin
    f.FruitSeedPeriodEnd
    f.FruitSeedPersistence
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
    f.SmallGrain
    f.VegetativeSpreadRate
    f.Berry_Nut_Seed_Product
    f.ChristmasTreeProduct
    f.FodderProduct
    f.FuelwoodProduct
    f.LumberProduct
    f.NavalStoreProduct
    f.NurseryStockProduct
    f.PalatableBrowseAnimal
    f.PalatableGrazeAnimal
    f.PalatableHuman
    f.PostProduct
    f.ProteinPotential
    f.PulpwoodProduct
    f.VeneerProduct
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
