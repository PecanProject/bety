module Api::JsonHandler

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

end
