class ModeltypesFormat < ActiveRecord::Base
  belongs_to :modeltype
  belongs_to :format
  belongs_to :user
end
