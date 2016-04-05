class Api::V0::BaseController < Api::BaseController
  include ApiAuthenticationSystem

  before_filter :login_required

  # Given a model, define +index+ and +show+ actions.
  #
  # The +index+ action will set instance variable @+row_set+ to the set of all
  # model instances whose column values match thoses specified by +params+.  The
  # +show+ action will set the instance variable @+row+ to the model instance
  # with id value <code>params[:id]</code>.
  def self.define_actions(model)
    define_method(:index) do
      @row_set = query(model, params)
      if !params.has_key?("limit") && @row_set.size > 200
        @warnings = "The #{@row_set.size}-row result set exceeds the default 200 row limit.  " +
          "Showing the first 200 results only.  Set an explicit limit to show more results."
        @row_set = @row_set.limit(200)
      else
        @errors = nil
      end
      @count = @row_set.size
    end

    define_method(:show) do
      id = params[:id]
      begin
        @row = model.find(id)
        @errors = nil
      rescue ActiveRecord::RecordNotFound
        @row = nil
        @errors = "Non-Existent Resource: No #{model} object with id #{id} was found."
      end
    end
  end

end
