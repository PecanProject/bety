
class Citation < ActiveRecord::Base

  include Overrides

  # Sorting and searching functionality
  extend SimpleSearch
  SEARCH_INCLUDES = %w{  }
  SEARCH_FIELDS = %w{ citations.author citations.year citations.title citations.journal citations.vol citations.pg citations.url citations.pdf }

  #Define relationships to other tables
  has_and_belongs_to_many :sites
  has_and_belongs_to_many :treatments
  has_many :managements
  has_many :yields
  has_many :traits
  has_many :priors
  has_many :ebi_methods, :class_name => "Methods"
  belongs_to :user

  # Predefined search filters
  named_scope :by_letter, lambda { |letter| { :conditions => ['author like ?', letter + "%"] } }
  # Must be included if using 'simple search'
  named_scope :order, lambda { |order| {:order => order, :include => SEARCH_INCLUDES } }
  named_scope :search, lambda { |search| {:conditions => simple_search(search) } } 

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
  
  # over ride the default of when you call a citation in a string
  # Better ways to do this, but this one works for me. 
  def to_s(format = nil)
    case format
    when :author_year
      "#{(author || "NA")[/^[\w-]*/]} #{year} "
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
