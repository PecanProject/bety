class FormatsVariable < ActiveRecord::Base
  attr_protected []

  belongs_to :format
  belongs_to :variable
end
