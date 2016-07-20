require 'memoist'
module Api::CsvHandler
  extend Memoist

  class BadHeading < Exception
  end

  private

  def csv_2_xml(csv_string)
    csv = CSV.new(csv_string, headers: true, return_headers: true)

    headers = csv.shift.headers

    doc = Nokogiri::XML::Document.new

    root = doc.create_element('trait-data-set')

    variable_info = HeadingVariableInfo.new(headers)

    csv.each do |row|
      if variable_info.multiple_traits_per_row?
        # wrap the set of traits for each row in a trait-group element and add an entity node
        trait_group_node = root.add_child(doc.create_element("trait-group"))

        # to-do: add the option to handle columns for entity name and entity notes
        trait_group_node.add_child(doc.create_element('entity'))

        variable_info.trait_list.each do |trait_name|
          covariates = variable_info.covariates_for(trait_name)
          trait_group_node.add_child(create_trait_element(doc, headers, row, trait_name, covariates))
        end
        #add traits to trait_group_node
      else
        # add traits directly to trait-data-set
        trait_name = variable_info.trait_list.first # and only
        covariates = variable_info.covariates_for(trait_name)
        root.add_child(create_trait_element(doc, headers, row, trait_name, covariates))
      end
    end
    doc.root = root
Rails.logger.debug(doc.to_s)
    return doc.to_s
  end

  # Consult the database table trait_covariate_associations to determine which
  # column headings correspond to trait names.
  def get_trait_names(headers)
    recognized_trait_names = TraitCovariateAssociations.all.collect { |tca| tca.variable.name }
  end

  # Creates a <trait> element in the XML document 'doc' corresponding to the row
  # 'row' in a CSV file having headers 'headers'.
  def create_trait_element(doc, headers, row, variable_name, covariates)
    trait_child_element_names = compute_trait_child_element_names(headers)
    varying_trait_attribute_names = compute_varying_trait_attribute_names(headers)

    trait = doc.create_element("trait")

    # add attributes
    Rails.logger.debug("variable_name = #{variable_name}; row = #{row}")
    trait.set_attribute("mean", row[variable_name])
    varying_trait_attribute_names.each do |name|
      trait.set_attribute(name, row[name])
    end

    # add child elements
    (trait_child_element_names + ['variable']).each do |name|
      child = doc.create_element(name)
      case name
      when "citation"
        ["doi", "author", "year", "title"].each do |attribute|
          key = "citation_" + attribute
          if row.has_key?(key)
            child.set_attribute(attribute, row[key])
          end
        end
      when "stat"
        child.set_attribute("name", "SE") # the only one supported for now
        child.set_attribute("sample_size", row["n"])
        child.set_attribute("value", row["SE"])
      when "site"
        child.set_attribute("sitename", row[name])
      when "species"
        child.set_attribute("scientificname", row[name])
        # check if there is a cultivar
        if headers.include?("cultivar") && !row["cultivar"].blank?
          cultivar = doc.create_element("cultivar")
          cultivar.set_attribute("name", row["cultivar"])
          child.add_child(cultivar)
        end
      when "treatment"
        child.set_attribute("name", row[name])
      when "variable"
        child.set_attribute("name", variable_name)
      when "method"
        # TO-DO: add support
      when "notes"
        child.set_attribute("notes", row[name])
      end
      trait.add_child(child)
    end

    # maybe add covariates
    if !covariates.blank?
      covariates_node = trait.add_child(doc.create_element("covariates"))
      covariates.each do |covariate_name, covariate_id|
        covariate_node = doc.create_element("covariate")
        covariate_node.set_attribute("level", row[covariate_name])
        variable_node = covariate_node.add_child(doc.create_element("variable"))
        variable_node.set_attribute("id", covariate_id)
        covariates_node.add_child(covariate_node)
      end
    end

    trait
  end

  def compute_trait_child_element_names(headers)
    child_element_name_list = headers & ["site", "species", "treatment", "variable", "method", "notes"]

    # add names of elements that require multiple columns
    if !(headers & ["citation_doi", "citation_author", "citation_title", "citation_year"]).empty?
      child_element_name_list << "citation"
    end

    if !(headers & ["SE", "n"]).empty?
      child_element_name_list << "stat"
    end

    child_element_name_list
  end
  memoize :compute_trait_child_element_names

  def compute_varying_trait_attribute_names(headers)
    attribute_list = headers & ["access_level", "utc_datetime", "local_datetime"]
  end
  memoize :compute_varying_trait_attribute_names

end

# To-Do: Factor similar code out of BulkUploadDataSet.
class HeadingVariableInfo

  def initialize(heading)

    # A list of TraitCovariateAssociation objects corresponding to trait
    # variable names occurring in the heading.  Used by +get_insertion_data+
    # when the upload file has trait data.
    relevant_associations = TraitCovariateAssociation.all.select { |a| heading.include?(a.trait_variable.name) }
    @trait_variables = relevant_associations.collect { |a| a.trait_variable }.uniq

    @heading_variable_info = {}

    @trait_variables.each do |tv|
      covariates = relevant_associations.select { |a| a.trait_variable_id = tv.id && heading.include?(a.covariate_variable.name) }.collect { |a| a.covariate_variable }
      covariate_hash = {}
      covariates.each do |c|
        covariate_hash[c.name] = c.id
      end
      @heading_variable_info[tv.name] = covariate_hash
    end

    if @trait_variables.size == 0
      raise Api::CsvHandler::BadHeading.new "No trait variable was found in the CSV file."
    end

  end

  def trait_list
    @trait_variables.collect { |tv| tv.name }
  end

  def multiple_traits_per_row?
    trait_list.size > 1
  end

  def covariates_for(trait_name)
    @heading_variable_info[trait_name]
  end
    

end
