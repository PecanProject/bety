require 'memoist'
module Api::CsvHandler
  extend Memoist

  private

  def csv_2_xml(csv_string)
    csv = CSV.new(csv_string, headers: true, return_headers: true)

    headers = csv.shift.headers

    doc = Nokogiri::XML::Document.new

    root = doc.create_element('trait-data-set')
    csv.each do |row|
      root.add_child(create_trait_element(doc, headers, row))
    end
    doc.root = root

    return doc.to_s
  end

  # Creates a <trait> element in the XML document 'doc' corresponding to the row
  # 'row' in a CSV file having headers 'headers'.
  def create_trait_element(doc, headers, row)
    trait_child_element_names = compute_trait_child_element_names(headers)
    trait_attribute_names = compute_trait_attribute_names(headers)

    trait = doc.create_element("trait")

    # add attributes
    trait_attribute_names.each do |name|
      trait.set_attribute(name, row[name])
    end

    # add child elements
    trait_child_element_names.each do |name|
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
        child.set_attribute("sample-size", row["n"])
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
        child.set_attribute("name", row[name])
      when "method"
        # TO-DO: add support
      when "notes"
        child.set_attribute("notes", row[name])
      end
      trait.add_child(child)
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

  def compute_trait_attribute_names(headers)
    attribute_list = headers & ["access_level", "mean", "utc-timestamp"]
  end
  memoize :compute_trait_attribute_names

end
