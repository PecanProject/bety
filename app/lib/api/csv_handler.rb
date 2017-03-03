require 'memoist'
module Api::CsvHandler
  extend Memoist

  class BadHeading < Exception
  end

  STAT_HEADING_NAMES = ["SE", "n"]

  CITATION_HEADING_NAMES = ["citation_doi", "citation_author",
                            "citation_title", "citation_year"]

  CHILD_ELEMENT_HEADING_NAMES = ["site", "species", "treatment",
                                 "variable", "method", "notes"]

  ALL_METADATA_HEADING_NAMES = STAT_HEADING_NAMES +
                               CITATION_HEADING_NAMES +
                               CHILD_ELEMENT_HEADING_NAMES


  private

  def csv_2_xml(csv_string)
    doc = csv_2_xml_doc(csv_string)
    doc_as_string = doc.to_s
    Rails.logger.debug(doc_as_string)
    doc_as_string
  end

  def csv_2_xml_doc(csv_string)
    csv = CSV.new(csv_string, headers: true, return_headers: true)

    headers = csv.shift.headers

    doc = Nokogiri::XML::Document.new

    root = doc.create_element('trait-data-set')

    variable_info = HeadingVariableInfo.new(headers)

    csv.each do |row|
      if variable_info.multiple_traits_per_row?
        # wrap the set of traits for each row in a trait-group element and add an entity node
        trait_group_node = root.add_child(doc.create_element("trait-group"))

        entity_node = doc.create_element('entity')
        if row.has_key?('entity')
          entity_node.set_attribute('name', row['entity'])
        else
          # anonymous entity used only for grouping traits:
          entity_node.set_attribute('name', '')
        end
        trait_group_node.add_child(entity_node)

        variable_info.trait_list.each do |trait_name|
          covariates = variable_info.covariates_for(trait_name)
          trait_group_node.add_child(create_trait_element(doc, headers, row, trait_name, covariates))
        end
        #add traits to trait_group_node
      else
        # add traits directly to trait-data-set
        trait_name = variable_info.trait_list.first # and only
        covariates = variable_info.covariates_for(trait_name)
        trait_node = create_trait_element(doc, headers, row, trait_name, covariates)
        if row.has_key?('entity')
          entity_node = doc.create_element('entity')
          entity_node.set_attribute('name', row['entity'])
          trait_node.add_child(entity_node)
        end
        root.add_child(trait_node)
      end
    end
    doc.root = root
    return doc
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
        child.set_attribute("name", row[name])
      when "notes"
        child.content = row[name]
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
    child_element_name_list = headers & CHILD_ELEMENT_HEADING_NAMES

    # add names of elements that require multiple columns
    if !(headers & CITATION_HEADING_NAMES).empty?
      child_element_name_list << "citation"
    end

    if !(headers & STAT_HEADING_NAMES).empty?
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

    relevant_associations = TraitCovariateAssociation.all.select do |a|
      heading.include?(a.trait_variable.name)
    end

    # A list of TraitCovariateAssociation objects corresponding to trait
    # variable names occurring in the heading.  Used by +get_insertion_data+
    # when the upload file has trait data.
    @trait_variables = relevant_associations.collect { |a|
      a.trait_variable
    }.uniq

    @heading_variable_info = {}

    covariate_list = [] # keep track of what covariates are in the heading
    @trait_variables.each do |tv|

      covariates = relevant_associations.select { |a|
        a.trait_variable_id =
          tv.id &&
          heading.include?(a.covariate_variable.name)
      }.collect { |a| a.covariate_variable }

      covariate_list += covariates

      covariate_hash = {}
      covariates.each do |c|
        covariate_hash[c.name] = c.id
      end
      @heading_variable_info[tv.name] = covariate_hash
    end


    # Add in any unrecognized headings that correspond to a trait variable
    # even if they aren't in the trait_covariate_associations_table:
    all_heading_variables = Variable.all.select do |v|
      (heading - Api::CsvHandler::ALL_METADATA_HEADING_NAMES).include?(v.name)
    end
    @trait_variables += (all_heading_variables - @trait_variables)



    # Ignore any variables corresponding to covariates of traits in
    # the heading:
    @trait_variables -= covariate_list


    # It is an error if there still any "covariate only" variable
    # names in the @trait_variables list:
    reserved_covariate_variables =
      TraitCovariateAssociation.all.collect { |a|
      a.covariate_variable
    }.uniq

    unmatched_covariates = (@trait_variables & reserved_covariate_variables)
                             .map { |c| c.name }
    if !unmatched_covariates.empty?
      error_message =  "Covariate variable(s) " \
                       "(#{unmatched_covariates.join(", ")}) with no " \
                       "matching trait variable was found in the CSV file " \
                       "heading"
      raise Api::CsvHandler::BadHeading.new(error_message)
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
