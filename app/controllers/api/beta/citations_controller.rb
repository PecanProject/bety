class Api::Beta::CitationsController < Api::Beta::BaseController

  def self.get_short_description
    "A research paper or collection of research data."
  end

  define_actions(Citation)
end
