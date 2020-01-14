require 'utilities/sql_comments.rb'

class Api::V1::BaseController < Api::BaseController
  include ApiAuthenticationSystem

  before_action :set_content_type # IMPORTANT: Run this filter first!
  before_action :login_required

  NO_CONSTRAINT = lambda { |value| true }


  # Set the response content type based on the "format" parameter.
  def set_content_type
    case params['format']
    when 'xml'
      response.headers['Content-Type'] = "application/xml; charset=utf-8"
    when 'json', 'csv'
      response.headers['Content-Type'] = "application/json; charset=utf-8"
    else
      raise "Unexpected format!"
    end
  end

  # Given a model, define +index+ and +show+ actions.
  #
  # The +index+ action will set instance variable @+row_set+ to the set of all
  # model instances whose column values match thoses specified by +params+.  The
  # +show+ action will set the instance variable @+row+ to the model instance
  # with id value <code>params[:id]</code>.
  def self.define_actions(model)

    # Use the value of the ShortDescription class constant if it exists;
    # otherwise fall back on using the description found in the database.
    # TO-DO: Consider defining descriptions on the Model rather than on the Controller.
    short_description = self.get_short_description ||
      Utilities::SQLComments::get_table_description(model.table_name)

    self.resource_description do
      api_versions "v1"
      short short_description
    end

    def_param_group :shared_parameters do
      param :key, NO_CONSTRAINT, :desc => "The API key to use for authorization."
      param :associations_mode, [ "full_info", "ids", "count" ],
            desc: <<-DESC
              Set the amount of data to display about associations.  Default is
              "full_info" for the show action and "count" for the index action.
            DESC
     end

    def_param_group :extra_parameters do
      param :limit, /^([1-9][0-9]*|all|none)$/,
            :desc => "Sets an upper bound on the number of results to return.  Defaults to 200."
      param :offset, /[1-9][0-9]*/,
            :desc => "Set the number of rows to skip before returning matching rows."
      param_group :shared_parameters
    end

    api!
    description <<-DESC
      Get all rows that match the values provided for all column-name parameters
      used.  If the value starts with a tilde ('~'), the rest of the value is
      treated as a regular expression to match and the matching is case
      insensitive.  Otherwise, the column value must match the parameter value
      exactly.
    DESC
    param_group :extra_parameters
    model.columns.each do |c|
      param c.name, get_validation(model, c),
            desc: Utilities::SQLComments::get_column_comment(model.table_name, c.name)
    end
    define_method(:index) do
      @associations_mode = params["associations_mode"].try(:to_sym) || :count
      begin
        @row_set = query(model, params)
        if !params.has_key?("limit") && @row_set.size > 200
          @warnings = "The #{@row_set.size}-row result set exceeds the default 200 row limit.  " +
                      "Showing the first 200 results only.  Set an explicit limit to show more results."
          @row_set = @row_set.limit(200)
        else
          @errors = nil
        end
      rescue => e # catch errors having to do with the query
        @row_set = []
        @errors = e
      end
      @count = @row_set.size
    end

    api!
    description <<-DESC
      Get all information about the row with the matching id value.  Information
      about associated rows (those reference by foreign keys) is shown as well.
    DESC
    param_group :shared_parameters
    define_method(:show) do
      @associations_mode = params["associations_mode"].try(:to_sym) || :full_info
      id = params[:id]
      begin
        @row = model.find(id)
        @errors = nil
        if [Trait, Yield].include? model
          required_access_level = @row.access_level

          if required_access_level < self.current_user.access_level &&
              self.current_user.id != @row.user_id

            @errors = "You must be an #{{
                    1 => "Administrator",
                    2 => "Internal Collaborator",
                    3 => "External Researcher" }[required_access_level]
                } to view this item."

            @row = nil

          end
        elsif model == User && current_user.page_access_level > 1 && id.to_i != current_user.id.to_i
          # Show current user's record instead of requested record
          id = current_user.id
          @errors = "You must be an Administrator to view this item."
          @row = nil
        end
      rescue ActiveRecord::RecordNotFound
        @row = nil
        @errors = "Non-Existent Resource: No #{model} object with id #{id} was found."
      end
    end

  end


  protected

  # helper method for setting validation type from column type
  def self.get_validation(model, column)

    case column.type
    when :string
      String
    when :integer
      :number
    else
      NO_CONSTRAINT
    end

    # For now, ignore validations:
    NO_CONSTRAINT

  end

  # Override this in child controllers to provide a customized description.
  # Otherwise, the description from the corresponding database table is used.
  def self.get_short_description
  end

end
