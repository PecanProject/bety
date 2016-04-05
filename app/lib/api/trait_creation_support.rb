module Api::TraitCreationSupport

  private

  class InvalidDocument < StandardError
  end

  class NotFoundException < StandardError
    def initialize(node, entity_name, selection_criteria)
      node.set_attribute("error", "match not found")
      super("No #{entity_name} could be found matching #{selection_criteria}")
    end
  end

  class NotUniqueException < StandardError
    def initialize(node, entity_name, selection_criteria)
      node.set_attribute("error", "multiple matches")
      super("Multiple #{entity_name} objects were found matching #{selection_criteria}")
    end
  end

  # Given data, and XML string, extract the information from it and insert
  # appropriate rows into the entities, traits, and covariates tables.
  def create_traits_from_post_data(data)

    begin

      doc = Nokogiri::XML(data, nil, nil, Nokogiri::XML::ParseOptions::STRICT)

      schema_validate(doc)

      trait_data_set_node = doc.root

      ActiveRecord::Base.transaction do

        # The root element "trait-data-set" can be treated just like a
        # "trait-group" node.
        process_trait_group_node(trait_data_set_node, {})

      end # transaction

    rescue StandardError => e

      e.backtrace.each do |line|
        if !line.match /\.rvm/
          logger.debug line
        end
      end
      logger.debug e.message

      raise e

    ensure

      if @lookup_errors.size > 0 ||
          @model_validation_errors.size > 0 ||
          @database_insertion_errors.size > 0
        @new_trait_ids = []
      end

    end

    return Hash.from_xml(doc.to_s)

  end # method

  def process_trait_group_node(trait_group_node, defaults)

    defaults = defaults.clone

    if trait_group_node.xpath("boolean(entity)")
      entity_node = trait_group_node.xpath("entity").first
      entity_attributes = attr_hash_2_where_hash(entity_node.attributes)
      new_entity = Entity.create!(entity_attributes)
      defaults[:entity_id] = new_entity.id
    end

    if trait_group_node.xpath("boolean(defaults)")
      defaults = merge_new_defaults(trait_group_node.xpath("defaults").first, defaults)
    end

    trait_group_node.xpath("trait").each do |trait_node|
      process_trait_node(trait_node, defaults)
    end

    trait_group_node.xpath("trait-group").each do |trait_group_node|
      process_trait_group_node(trait_group_node, defaults)
    end

  end


  def process_trait_node(trait_node, defaults)

    defaults = defaults.clone

    if !defaults.has_key?(:entity_id)
      # Make an anonymous singleton entity for this trait
      new_entity = Entity.create!
      defaults[:entity_id] = new_entity.id
    end

    column_values = merge_new_defaults(trait_node, defaults)

    # add stat info
    column_values.merge!(get_stat_info(trait_node))

    column_values[:mean] = trait_node.attribute("mean").value

    column_values[:notes] = (trait_node.xpath("notes").first && trait_node.xpath("notes").first.content) || ""

    # Set dateloc and timeloc to 9 ("no data") if no date was given:
    if !column_values.has_key? :date
      column_values[:dateloc] = 9
      column_values[:timeloc] = 9
    end

    begin

      new_trait = Trait.create!(column_values)

      @new_trait_ids << new_trait.id

      if trait_node.xpath("boolean(covariates)")

        trait_node.xpath("covariates/covariate").each do |covariate_node|

          column_values = get_foreign_keys(covariate_node) # get variable_id

          column_values[:level] = covariate_node.attribute("level").value

          column_values[:trait_id] = new_trait.id

          Covariate.create!(column_values)

        end

      end

    rescue ActiveRecord::RecordInvalid => invalid
      # add error info to trait node
      trait_node.set_attribute("model_validation_errors", invalid.record.errors.messages)
      @model_validation_errors << "#{invalid.record.errors.messages}"
      return
    rescue ActiveRecord::StatementInvalid => e
      # Note: In Rails 4 we can get information from the original_exception attribute
      message = e.message.sub!(/.*ERROR: *([^\n]*).*/m, '\1')
      trait_node.set_attribute("database_exception", message)
      @database_insertion_errors << message
      raise # Don't continue with this transaction -- it's unstable.
    end

  end

  def merge_new_defaults(element_node, defaults)

    defaults = defaults.clone

    defaults.merge!(get_foreign_keys(element_node))

    date = get_date(element_node)
    if date
      defaults[:date] = date
      # For now at least, assume dates are accurate to the second and are on a
      # definite date of a definite year:
      defaults[:dateloc] = 5
      defaults[:timeloc] = 1
    end

    new_access_level  = get_access_level(element_node)
    if new_access_level
      defaults[:access_level] = new_access_level
    end

    return defaults
  end

  def get_date(element_node)
    element_node.attribute("utc-timestamp") && element_node.attribute("utc-timestamp").value
  end

  def get_stat_info(element_node)
    stat_info = {}
    if element_node.xpath("boolean(stat)")
      stat_node = element_node.xpath("stat").first
      stat_info[:statname] = stat_node.attribute("name").value
      stat_info[:n] = stat_node.attribute("sample-size").value
      stat_info[:stat] = stat_node.attribute("value").value
    end
    return stat_info
  end

  def get_access_level(element_node)
    element_node.attribute("access_level") && element_node.attribute("access_level").value
  end


  # Given an element node containing child elements corresponding to the
  # foreign-key columns in the traits table, look up the id to use for each
  # foreign key.
  def get_foreign_keys(parent_node)
    id_hash = {}

    parent_node.element_children.each do |child_node|

      entity_name = child_node.name
      if !["site", "species", "citation", "treatment", "variable", "method"].include? entity_name
        next
      end

      selection_criteria = attr_hash_2_where_hash(child_node.attributes)

      if entity_name != "species"
        model = (entity_name == "method") ? Methods : entity_name.classify.constantize
        foreign_key = (entity_name + "_id").to_sym
      end

      begin
        case child_node.name

        when "species"
          # If there is a cultivar specified, get cultivar_id:
          if child_node.xpath("boolean(cultivar)")
            cultivar_selection_criteria = attr_hash_2_where_hash(child_node.xpath("cultivar").first.attributes)
            matches = Cultivar.where(cultivar_selection_criteria)
            if matches.size == 0
              raise NotFoundException.new(child_node, "cultivar", cultivar_selection_criteria)
            elsif matches.size > 1
              raise NotUniqueException.new(child_node, "cultivar", cultivar_selection_criteria)
            end
            id_hash[:cultivar_id] = matches.first.id
          else
            # Don't keep cultivar_id associated with overriden species:
            id_hash[:cultivar_id] = nil
          end

          matches = Specie.where(selection_criteria)
          if matches.size == 0
            raise NotFoundException.new(child_node, entity_name, selection_criteria)
          elsif matches.size > 1
            raise NotUniqueException.new(child_node, entity_name, selection_criteria)
          end
          id_hash[:specie_id] = matches.first.id
        else
          matches = model.where(selection_criteria)
          if matches.size == 0
            raise NotFoundException.new(child_node, entity_name, selection_criteria)
          elsif matches.size > 1
            raise NotUniqueException.new(child_node, entity_name, selection_criteria)
          end
          id_hash[foreign_key] = matches.first.id
        end # case
      rescue NotFoundException, NotUniqueException => e
        @lookup_errors << e.message
      end

    end # children.each

    return id_hash
  end

  # Validate the XML document "doc" using the TraitData.xsd schema.  Raise and
  # InvalidDocument exception containing the list of errors returned by the
  # parser if the document is not valid.
  def schema_validate(doc)

    xsd = Nokogiri::XML::Schema.from_document(
      Nokogiri::XML(Rails.root.join('app', 'lib', 'api', 'validation', 'TraitData.xsd').open,
                    nil,
                    nil,
                    Nokogiri::XML::ParseOptions::STRICT))

    xsd.validate(doc).each do |error|
      @schema_validation_errors << error.message
    end

    if !@schema_validation_errors.blank?
      raise InvalidDocument, @schema_validation_errors
    end


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

  def json_2_xml(json_string)
    doc_as_hash = Yajl::Parser.parse(json_string)

    doc = Nokogiri::XML::Document.new

    def create_element(doc, hash)
      if hash.keys.size != 1
        raise "Unexpected hash size"
      end

      element_name = hash.keys.first

      element = doc.create_element(element_name)

      inner_hash = hash[element_name]

      if inner_hash.has_key? "attributes"
        inner_hash["attributes"].each_pair do |k, v|
          element.set_attribute(k, v)
        end
      end

      if inner_hash.has_key? "children"
        inner_hash["children"].each do |c|
          if c.has_key?( "content") && c["content"].is_a?(String)
            element.content = c["content"]
          else
            element.add_child(create_element(doc, c))
          end
        end
      end

      return element
    end

    # Use create_element to recursively create the document contents from the
    # Hash we got from the JSON text:
    doc.root = create_element(doc, doc_as_hash)

    # Return the textual rendition of the XML document:
    return doc.to_s
  end

end
