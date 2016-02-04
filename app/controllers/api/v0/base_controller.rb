class Api::V0::BaseController < Api::BaseController

  # Given a model, define +index+ and +show+ actions.
  #
  # The +index+ action will set instance variable @+row_set+ to the set of all
  # model instances whose column values match thoses specified by +params+.  The
  # +show+ action will set the instance variable @+row+ to the model instance
  # with id value <code>params[:id]</code>.
  def self.define_actions(model)
    define_method(:index) do
      @row_set = query(model, params)
      @error = nil
    end

    define_method(:show) do
      id = params[:id]
      begin
        @row = model.find(id)
        @error = nil
      rescue ActiveRecord::RecordNotFound
        @row = nil
        @error = "Non-Existent Resource: No #{model} object with id #{id} was found."
      end
    end
  end

end
