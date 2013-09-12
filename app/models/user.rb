require 'digest/sha1'

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken

  extend SimpleSearch
  SEARCH_INCLUDES = %w{  }
  SEARCH_FIELDS = %w{ users.login users.name users.email }

  has_many :traits
  has_many :yields
  has_many :citations
  has_many :managements
  has_many :treatments
  has_many :sites

  scope :sorted_order, lambda { |order| order(order).includes(SEARCH_INCLUDES) }
  scope :search, lambda { |search| where(simple_search(search)) }

  validates_presence_of     :login
  validates_length_of       :login,    :within => 3..40
  validates_uniqueness_of   :login
  validates_format_of       :login,    :with => Authentication.login_regex, :message => Authentication.bad_login_message

  validates_format_of       :name,     :with => Authentication.name_regex,  :message => Authentication.bad_name_message, :allow_nil => true
  validates_length_of       :name,     :maximum => 100

  validates_presence_of     :email
  validates_length_of       :email,    :within => 6..100 #r@a.wk
  validates_uniqueness_of   :email
  validates_format_of       :email,    :with => Authentication.email_regex, :message => Authentication.bad_email_message

  validates_presence_of     :access_level
  validates_presence_of     :page_access_level
  #validates_length_of       :apikey,   :minimum => 40
  

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.  
  attr_accessible :login, :email, :name, :password, :password_confirmation, :city, :area, :country, :access_level, :page_access_level, :apikey, :postal_code, :state_prov



  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.  
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_by_login(login.downcase) # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  def create_apikey
    write_attribute :apikey, (0...40).collect { ((48..57).to_a + (65..90).to_a + (97..122).to_a)[Kernel.rand(62)].chr }.join
  end

  def to_s
    name
  end
  def select_default
    "#{id}: #{self}"
  end

  protected
    


end
