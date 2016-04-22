require 'memoist'
module Api::ContentTypeConversion
  extend Memoist

  private

  ##### JSON HANDLING #####

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

  ##### CSV HANDLING #####

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

  def compute_trait_attribute_names(headers)
    attribute_list = headers & ["access_level", "mean", "utc-timestamp"]
  end
  memoize :compute_trait_attribute_names

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

end
