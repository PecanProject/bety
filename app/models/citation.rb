
class Citation < ActiveRecord::Base

  has_and_belongs_to_many :sites
  has_and_belongs_to_many :treatments

  has_many :managements
  has_many :yields
  has_many :traits
  has_many :priors
  has_many :ebi_methods, :class_name => "Methods"

  belongs_to :user

  #named_scope :all, :order => 'author, year'

  named_scope :by_letter, lambda { |letter| { :conditions => ['author like ?', letter + "%"] } }


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

  def author_year
    "#{(author || "NA")[/^[\w-]*/]} #{year} "
  end
  def author_year_title
    "#{author_year} #{(title || "NA")[0..19]}..."
  end
  def to_s
    author_year_title
  end
  def select_default
    "#{id}: #{self}"
  end
  
  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    ["citations.id", "citations.author", "citations.year", "citations.title"]
  end

end
