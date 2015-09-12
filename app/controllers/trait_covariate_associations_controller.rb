class TraitCovariateAssociationsController < ApplicationController

  def index
    @recognized_traits = TraitCovariateAssociation.all.map { |tca| Variable.find(tca.trait_variable_id) }.uniq
  end

end
