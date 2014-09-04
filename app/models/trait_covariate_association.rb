class TraitCovariateAssociation < ActiveRecord::Base

  belongs_to :trait_variable, :class_name => 'Variable'
  belongs_to :covariate_variable, :class_name => 'Variable'

end

