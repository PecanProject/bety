class Api::V1::CitationsController < Api::V1::BaseController

  def self.get_short_description
    "A research paper or collection of research data."
  end

  define_actions(Citation)
end
