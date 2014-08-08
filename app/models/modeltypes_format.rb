class ModeltypesFormat < ActiveRecord::Base
  validates :tag, presence: true
  validates_uniqueness_of :tag, scope: :modeltype_id
  
  belongs_to :modeltype
  belongs_to :format
  belongs_to :user
end
