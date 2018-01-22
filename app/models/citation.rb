require 'whitespace_normalizer'

class Citation < ActiveRecord::Base
  attr_protected []

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{  }
  SEARCH_FIELDS = %w{ citations.author citations.year citations.title citations.journal citations.vol citations.pg citations.url citations.doi }

  has_many :citation_sites, :class_name => "CitationsSites"
  has_many :sites, :through =>  :citation_sites

  has_many :citation_treatments, :class_name => "CitationsTreatments"
  has_many :treatments, :through =>  :citation_treatments

  has_many :managements
  has_many :yields
  has_many :traits
  has_many :priors
  has_many :ebi_methods, :class_name => "Methods"
  belongs_to :user


  # VALIDATION

  ## Validation methods

  def year_cannot_be_in_the_future
    year_limit = Date.today.year + 1
    if year.present? && year > year_limit
      errors.add(:year, "can't be more than one year in the future (#{year_limit})")
    end
  end

  ## Validation callback methods

  def normalize_page_numbers
    self.pg = self.pg.strip.sub(/ *- */, "\u2013") || ''
  end

  ## Validation callbacks

  before_validation WhitespaceNormalizer.new([:author, :title, :journal]), :normalize_page_numbers

  ## Validations

  validates_presence_of :author, :title
  validate :year_cannot_be_in_the_future
  validates :year,
      presence: true,
      numericality: { only_integer: true,
                      greater_than: 1800 }
  validates :vol,
      numericality: { only_integer: true,
                      greater_than_or_equal_to: 0 },
      unless: Proc.new { |a| a.vol.blank? }
  validates_format_of :pg, with: /\A([1-9]\d*(\u2013[1-9]\d*)?)?\z/, message: "must be a single page number or two numbers separated by a dash"
  validates :url, url: true
  validates :pdf, url: true
  validates_format_of :doi, with: /\A(|10\.\d+(\.\d+)?\/.+)\z/, message: "must begin with '10.'"


  # SCOPES

  scope :by_letter, lambda { |letter| where('author like ?', letter + "%") }
  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES).references(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  # CSV download default fields/field order
  comma do
    id
    author
    year
    title
    journal
    vol
    pg
    url
    pdf
    created_at
    updated_at
    doi
  end

  # Some functions for spitting out preformatted info
  def author_year
    self.to_s(:author_year)
  end
  def author_year_title
    self.to_s
  end

  # for now
  alias_method :autocomplete_label, :author_year_title
  
  # override the default of when you call a citation in a string
  # Better ways to do this, but this one works for me. 
  def to_s(format = nil)
    case format
    when :author_year
      "#{(author || "NA")[/[\w-][^,]*/]} #{year}"
    else
      "#{author_year} #{(title || "NA")[0..19]}..."
    end
  end
  # Used in forms to unify fields show in select boxes across site.
  def select_default
    "#{id}: #{self}"
  end
  
  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    ["citations.id", "citations.author", "citations.year", "citations.title"]
  end



end
