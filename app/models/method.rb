class Methods < ActiveRecord::Base
  belongs_to :citation
  has_many :traits
  has_many :yields
end
