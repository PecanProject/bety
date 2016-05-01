require 'yajl'


class Api::Beta::TraitsController < Api::Beta::BaseController

  include TraitCreationSupport

  define_actions(Trait)

  api!
  description <<-DESC
    Create new traits from the data specified in the posted data.  Data about
    traits to be inserted can be supplied in either JSON (the default), CSV
    (using create.csv), or XML (using create.xml) format.
  DESC
  param :key, lambda {|val| true }, :desc => "The apikey to use for authorization."
  formats ["json", "csv", "xml"]
  def create
    response.headers['Content-Type'] = "application/json" # the default
    case params['format']
    when 'xml'
      response.headers['Content-Type'] = "application/xml"
      xml_data = request.raw_post
    when 'json'
      begin
        xml_data = json_2_xml(request.raw_post)
      rescue Yajl::ParseError => e
        @errors = "Request data is not a well-formed JSON document. #{e.message}"
        raise
      end
    when 'csv'
      xml_data = csv_2_xml(request.raw_post)
    else
      raise "Unsupported API format"
    end
    create_from_xml_string(xml_data)

    render status: 201, content_type: "application/xml"

  rescue Nokogiri::XML::SyntaxError, InvalidDocument, Yajl::ParseError

    render status: 400

  end



  private

  def create_from_xml_string(data)

    @new_trait_ids = []

    @schema_validation_errors = []
    @lookup_errors = []
    @model_validation_errors = []
    @database_insertion_errors = []

    @result = create_traits_from_post_data(data)

  rescue Nokogiri::XML::SyntaxError

    @errors = "Request data is not a well-formed XML document."

    raise

  rescue InvalidDocument

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

    raise

  end

end
