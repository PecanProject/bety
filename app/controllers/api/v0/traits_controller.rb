require 'yajl'


class Api::V0::TraitsController < Api::V0::BaseController

  include TraitCreationSupport

  define_actions(Trait)

  def create
    @trait = Trait.new(params.slice(*Trait.column_names).merge({access_level: 1}))
    @trait.save!
  rescue => e
    @error = "Couldn't create trait: #{@trait.errors.messages}"
  end

  def create_csv
    data = request.raw_post

    logger.debug "data = #{data}"

    require 'csv'

    csv = CSV.new(data, headers: true)

    result = Trait.transaction do

      csv.each do |row|

        logger.debug "about to create new Trait from this: #{row}"

        Trait.create!(row.to_hash)

      end

    end

    render text: result
  end

  def create_json
    data = request.raw_post

    xml = json_2_xml(data)

    create_from_xml_string(xml)

  end


  def create_xml
    data = request.raw_post

    create_from_xml_string(data)

  rescue Exception => e
    logger.debug "RESCUE CLAUSE!!!"
    @error = "This error occurred: #{e.class}\n#{e.message}\n"##{e.backtrace.join("\n")}\n"
  end



  private

  def create_from_xml_string(data)

    @new_trait_ids = []

    @schema_validation_errors = []
    @lookup_errors = []
    @model_validation_errors = []
    @database_insertion_errors = []

    @result = create_traits_from_post_data(data)

    @error = { }

    if !@schema_validation_errors.blank?
      @error[:schema_validation_errors] = @schema_validation_errors
    else
      if !@lookup_errors.blank?
        @error[:lookup_errors] = @lookup_errors
      end
      if !@model_validation_errors.blank?
        @error[:model_validation_errors] = @model_validation_errors
      end
      if !@database_insertion_errors.blank?
        @error[:database_insertion_errors] = @database_insertion_errors
      end
    end

  end

end
