require 'yajl'


class Api::V0::TraitsController < Api::V0::BaseController

  include TraitCreationSupport

  define_actions(Trait)

  def create
    case params['format']
    when 'xml'
      xml_data = request.raw_post
    when 'json'
      xml_data = json_2_xml(request.raw_post)
    else
      raise "Unsupported API format"
    end
    create_from_xml_string(xml_data)
  end



  private

  def create_from_xml_string(data)

    @new_trait_ids = []

    @schema_validation_errors = []
    @lookup_errors = []
    @model_validation_errors = []
    @database_insertion_errors = []

    @result = create_traits_from_post_data(data)

    @errors = { }

    if !@schema_validation_errors.blank?
      @errors[:schema_validation_errors] = @schema_validation_errors
    else
      if !@lookup_errors.blank?
        @errors[:lookup_errors] = @lookup_errors
      end
      if !@model_validation_errors.blank?
        @errors[:model_validation_errors] = @model_validation_errors
      end
      if !@database_insertion_errors.blank?
        @errors[:database_insertion_errors] = @database_insertion_errors
      end
    end

  end

end
