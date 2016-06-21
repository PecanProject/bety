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
    case params['format']
    when 'xml'
      xml_data = request.raw_post
    when 'json'
      begin
        xml_data = json_2_xml(request.raw_post)
      rescue Yajl::ParseError => e
        @errors = "Request data is not a well-formed JSON document. #{e.message}"
        raise
      end
    when 'csv'
      begin
        xml_data = csv_2_xml(request.raw_post)
      rescue Api::CsvHandler::BadHeading => e
        @errors = e.message
        raise
      end
    else
      raise "Unsupported API format"
    end
    create_from_xml_string(xml_data)

    render status: 201, content_type: "application/xml"

  rescue Nokogiri::XML::SyntaxError, InvalidDocument, InvalidData,
    Yajl::ParseError, Api::CsvHandler::BadHeading

    render status: 400

  end



  private

  def create_from_xml_string(data)

    @new_trait_ids = []

    @schema_validation_errors = []
    @lookup_errors = []
    @model_validation_errors = []
    @database_insertion_errors = []
    @date_data_errors = []

    create_traits_from_post_data(data)

  rescue Nokogiri::XML::SyntaxError

    @errors = "Request data is not a well-formed XML document."

    raise

  rescue InvalidDocument

    @errors = { }
    @errors[:schema_validation_errors] = @schema_validation_errors

    raise

  rescue InvalidData => e
    @errors = { }
    if !@lookup_errors.blank?
      @errors[:lookup_errors] = @lookup_errors
    end
    if !@model_validation_errors.blank?
      @errors[:model_validation_errors] = @model_validation_errors
    end
    if !@database_insertion_errors.blank?
      @errors[:database_insertion_errors] = @database_insertion_errors
    end
    if !@date_data_errors.blank?
      @errors[:date_data_errors] = @date_data_errors
    end

    raise

  end

end
