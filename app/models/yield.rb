class Yield < ActiveRecord::Base

  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ citation specie site treatment cultivar }
  SEARCH_FIELDS = %w{ species.genus cultivars.name yields.mean yields.n yields.stat yields.statname citations.author sites.sitename treatments.name }

  belongs_to :citation
  belongs_to :site
  belongs_to :specie
  belongs_to :treatment
  belongs_to :cultivar
  belongs_to :user
  belongs_to :ebi_method, :class_name => 'Methods', :foreign_key => 'method_id'

  validates_presence_of     :mean
  validates_presence_of     :statname, :if => Proc.new { |y| !y.stat.blank? }

  named_scope :all_order, :include => :specie, :order => 'species.genus, species.species'
  named_scope :order, lambda { |order| {:order => order, :include => SEARCH_INCLUDES } }
  named_scope :search, lambda { |search| {:conditions => simple_search(search) } } 
  named_scope :citation, lambda { |citation|
    if citation.nil?
      {}
    else
      { :conditions => ["citation_id = ?", citation ] }
    end
  }
  named_scope :all_limited, lambda { |current_user|
    if !current_user.nil?
      if current_user.page_access_level == 1
        checked = -1
        access_level = 1
      elsif current_user.page_access_level <= 2
        checked = -1
        access_level = current_user.access_level
      else
        checked = 1
        access_level = current_user.access_level
      end
      user = current_user
    else
      user = 1000000000000
      checked = 1
      access_level = 4
    end

    {:conditions => ["(checked >= ? and access_level >= ?) or yields.user_id = ?",checked,access_level,user] }
  }

  comma do
    id
    citation_id
    site_id
    specie_id
    treatment_id
    cultivar_id
    date
    dateloc
    statname
    stat
    mean
    n
    notes
    created_at
    updated_at
    user_id
    checked
    access_level
  end

  comma :test_pat do
    checked
  end

  comma :show_yields do |f|
     site :city_state
     specie :scientificname
     citation :author_year
     cultivar :sn_name
     treatment :name_definition

  end

  def to_s
    id
  end

  #Columns we search when referenced from another model
  #Fields present in 'select_default'
  def self.search_columns
    return ["yields.id"]
  end

end
