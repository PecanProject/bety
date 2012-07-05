class ContainersFile < ActiveRecord::Base
  belongs_to :container, :polymorphic => true
  belongs_to :file, :class_name => 'BetyFile'
end
