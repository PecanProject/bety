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

    logger.debug "data = #{data}"

    parser = Yajl::Parser.new(:symbolize_keys => true)

    trait_array = parser.parse(data)


    result = Trait.transaction do

      trait_array.each do |trait|

        logger.debug "about to create new Trait from this: #{trait}"

        Trait.create!(trait)

      end

    end


    render text: "result = #{result}"
  end


  def create_xml
    data = request.raw_post

    @trait_ids = []
    begin
      result = create_traits_from_post_data(data)
    rescue InvalidDocument => e
      #render text: e.message + "\n"
      @error = { schema_validation_errors: Yajl::Parser.parse(e.message) }
      return
    end

    #render text: "Success!  These traits were created: #{@trait_ids}"

  rescue => e
    @error = "This error occurred: #{e.class}\n#{e.message}\n#{e.backtrace.join("\n")}\n"
  end



  private

  def get_unique_match_id(model, element)
    column_values = attr_hash_2_where_hash(element.attributes)
    matches = model.where(column_values)
    if matches.size > 1
      raise "No unique variable matches has these column values: #{column_values}"
    elsif matches.size == 0
      raise "No variable matches has these column values: #{column_values}"
    end

    return matches.first.id
  end

  def attr_hash_2_where_hash(h)
    Hash[h.map { |k, v| [canonicalize_key(k), v.value] }]
  end

  def canonicalize_key(k)
    case k
      when "access-level", "variable-id"
      return k.sub(/-/, '_').to_sym
    else
      return k.to_sym
    end
  end

end
