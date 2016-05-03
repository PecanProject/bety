class Sitegroup < ActiveRecord::Base
  include Overrides

  extend SimpleSearch
  SEARCH_INCLUDES = %w{ }
  SEARCH_FIELDS = %w{ sitegroups.name }

  before_validation WhitespaceNormalizer.new([:name])
  validates_presence_of :name

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :access, lambda { |user|
    if defined?(user.id).nil?
      where('public_access')
    elsif user.page_access_level != 1
      where('public_access OR user_id=?', user.id)
    end
  }
  scope :search, lambda { |search| where(simple_search(search)) }

  has_many :sitegroup_sites, :class_name => "SitegroupsSites"
  has_many :sites, :through =>  :sitegroup_sites
  belongs_to :user

  def select_default
    self.to_s
  end

  def to_s
    name
  end

end
