module TraitCreationSupport

  class InvalidDocument < Exception
  end

  # Given data, and XML string, extract the information from it and insert
  # appropriate rows into the entities, traits, and covariates tables.
  def create_traits_from_post_data(data)

    doc = Nokogiri::XML(data)

    schema_validate(doc)

    trait_data_set_node = doc.root

    
    ActiveRecord::Base.transaction do

      # The root element "trait-data-set" can be treated just like a
      # "trait-group" node.
      process_trait_group_node(trait_data_set_node, {})

    end # transaction

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

    column_values[:mean] = trait_node.attribute("mean").value

    column_values[:notes] = (trait_node.xpath("notes").first && trait_node.xpath("notes").first.content) || ""

    new_trait = Trait.create!(column_values)

    @trait_ids << new_trait.id

    if trait_node.xpath("boolean(covariates)")

      trait_node.xpath("covariates/covariate").each do |covariate_node|
        column_values = get_foreign_keys(covariate_node) # get variable_id
        
        column_values[:level] = covariate_node.attribute("level").value

        column_values[:trait_id] = new_trait.id

        
        Covariate.create!(column_values)

      end

    end
        

  end

  def merge_new_defaults(element_node, defaults)

    defaults = defaults.clone

    defaults.merge!(get_foreign_keys(element_node))

    date = get_date(element_node)
    if date
      defaults[:date] = date
    end
    defaults.merge!(get_stat_info(element_node))
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

    parent_node.children.each do |child_node|

      where_hash = attr_hash_2_where_hash(child_node.attributes)

      case child_node.name
      when "site"
        matches = Site.where(where_hash)
        if matches.size != 1
          raise "no unique site matches #{where_hash}"
        end
        id_hash[:site_id] = matches.first.id
      when "species"
        matches = Specie.where(where_hash)
        if matches.size != 1
          raise "no unique species matches #{where_hash}"
        end
        id_hash[:specie_id] = matches.first.id

        # If there is a cultivar specified, get cultivar_id:
        if child_node.xpath("boolean(cultivar)")
          where_hash = attr_hash_2_where_hash(child_node.xpath("cultivar").first.attributes)
          matches = Cultivar.where(where_hash)
          if matches.size != 1
            raise "no unique cultivar matches #{where_hash}"
          end
          id_hash[:cultivar_id] = matches.first.id
        else
          # Don't keep cultivar_id associated with overriden species:
          id_hash[:cultivar_id] = nil
        end
      when "citation"
        matches = Citation.where(where_hash)
        if matches.size != 1
          raise "no unique citation matches #{where_hash}"
        end
        id_hash[:citation_id] = matches.first.id
      when "method"
        matches = Methods.where(where_hash)
        if matches.size != 1
          raise "no unique method matches #{where_hash}"
        end
        id_hash[:method_id] = matches.first.id
      when "treatment"
        matches = Treatment.where(where_hash)
        if matches.size != 1
          raise "no unique treatment matches #{where_hash}"
        end
        id_hash[:treatment_id] = matches.first.id
      when "variable"
        matches = Variable.where(where_hash)
        if matches.size != 1
          raise "no unique variable matches #{where_hash}"
        end
        id_hash[:variable_id] = matches.first.id
      end
    end

    return id_hash
  end





































=begin
        variable = trait.at_xpath "variable"
        if variable
          column_values[:variable_id] = get_unique_match_id(Variable, variable)
        end
        #logger.debug "about to create new Trait with these column values: #{column_values}"
=end

  def get_site_id(trait_node)
    site_node = trait_node.at_xpath "(ancestor-or-self::*/site)[1]"

    site_id = site_node.attributes["site_id"]

    Rails.logger.debug("SITE ID = #{site_id}")

  end

  def create_traits_from_post_data_old(data)

    #logger.debug "data = #{data}"

    doc = Nokogiri::XML(data)

    ########### validation #############

    xsd = Nokogiri::XML::Schema(Rails.root.join('api_stuff', 'TraitData.xsd').read)

    errors = ''
    xsd.validate(doc).each do |error|
      errors += error.message + "\n"
    end

    if !errors.blank?
      raise InvalidDocument, errors
    end

    ####################################

    #logger.debug(doc.root)
    #logger.debug(doc.root.elements)

    doc.root.elements.each do |e|
      #logger.debug(e.attributes)
    end


    result = Trait.transaction do

      doc.root.elements.each do |trait|

        get_site_id(trait)

        column_values = attr_hash_2_where_hash(trait.attributes)

        variable = trait.at_xpath "variable"
        if variable
          column_values[:variable_id] = get_unique_match_id(Variable, variable)
        end
        #logger.debug "about to create new Trait with these column values: #{column_values}"

        Trait.create!(column_values)

      end

   
    end

    return result

  end


  # Validate the XML document "doc" using the TraitData.xsd schema.  Raise and
  # InvalidDocument exception containing the list of erros returned by the
  # parser if the document is not valid.
  def schema_validate(doc)

    xsd = Nokogiri::XML::Schema(Rails.root.join('api_stuff', 'TraitData.xsd').open)

    errors = []
    xsd.validate(doc).each do |error|
      errors << error.message
    end

    if !errors.blank?
      raise InvalidDocument, errors
    end


  end


end
