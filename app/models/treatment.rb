class Treatment < ActiveRecord::Base

  include Overrides

  has_many :traits
  has_many :yields

  has_many :managements_treatments, :class_name => "ManagementsTreatments"
  has_many :managements, :through => :managements_treatments

  has_many :citations_treatments, :class_name => "CitationsTreatments"
  has_many :citations, :through => :citations_treatments

  belongs_to :user

  ## Validation callbacks

  before_validation WhitespaceNormalizer.new([:name, :definition])


  scope :sorted_order, lambda { |order| order(order) }


  comma do
    id
    name
    definition
    created_at
    updated_at
    control
  end

  # Returns an Array containing all treatment names that are associated with
  # every Citation whose id is in +citation_id_list+.  +citation_id_list+ may be
  # given as a single Array, as multiple integer arguments, or as some
  # combination of the two.
  def self.in_all_citations(*citation_id_list)
    where_condition = <<"CONDITION"
EXISTS (
    SELECT 1 FROM citations_treatments ct
        WHERE ct.treatment_id = treatments.id
            AND ct.citation_id = ?)
CONDITION
    common_treatment_names = nil
    citation_id_list.flatten.each do |citation_id|
      treatment_names = Treatment.where(where_condition, citation_id).collect {|t| t.name.squish}
      if common_treatment_names.nil?
        common_treatment_names = treatment_names
      else
        common_treatment_names &= treatment_names
      end
    end
    return common_treatment_names
  end

  def name_definition
    "#{name} : #{(definition || "NA")[0..19]}"
  end
  def name_definition_w_citation
    "#{name_definition} - #{citations.collect(&:author_year).join(',')}"
  end
  def to_s 
    name_definition_w_citation
  end
  def select_default 
    "#{id}: #{self}"
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["treatments.id", "treatments.name", "treatments.definition"]
  end

end
