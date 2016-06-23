# -*- coding: utf-8 -*-
require 'spec_helper'

RSpec.describe "Trait insertion API:" do

  RSpec.shared_examples "format" do |data_file, type, format_extension, content_type|

    context "a valid document is sent" do

      let(:valid_data_doc) { File.open(Rails.root.join data_file).read }

      let(:path) { "/api/beta/traits#{format_extension}" }

      specify <<-MESSAGE do

        Posting to /api/beta/traits#{format_extension}?key=... using
        the apikey of a creator should do database insertions, return
        with status 201 (Created), respond with the correct content
        type, and return a document of the correct form
        MESSAGE

        aggregate_failures "Insertion works correctly" do
          expect {
            post "#{path}?key=3333333333333333333333333333333333333333", valid_data_doc
          }.to change { Trait.count }.by(1)
            .and change { Entity.count }.by(1)
            .and change { Covariate.count }.by(2)
          expect(response.content_type).to eq(content_type)
          if response.content_type == "application/xml"
            expect(Hash.from_xml(response.body).fetch("hash").keys).to match_array(['metadata', 'data'])
          else
            expect(Yajl::Parser.parse(response.body).keys).to match_array(['metadata', 'data'])
          end
          expect(response.status).to eq 201
        end

      end


      specify <<-MESSAGE do

        Posting to /api/beta/traits#{format_extension}?key=... using
        the apikey of a viewer should not allow database insertions,
        return with status 401 (Unauthorized), respond with the
        correct content type, and return a document of the correct
        form
        MESSAGE

        aggregate_failures "Insertion fails without proper authorization" do
          expect {
            post "#{path}?key=4444444444444444444444444444444444444444", valid_data_doc
          }.to change { Trait.count }.by(0)
            .and change { Entity.count }.by(0)
            .and change { Covariate.count }.by(0)
          expect(response.content_type).to eq(content_type)
          if response.content_type == "application/xml"
            expect(Hash.from_xml(response.body).fetch("hash").keys).to match_array(['metadata', 'errors'])
          else
            expect(Yajl::Parser.parse(response.body).keys).to match_array(['metadata', 'errors'])
          end
          expect(response.status).to eq 401
        end

      end

    end

  end

  # JSON endpoint
  describe "JSON:" do
    include_examples "format", "spec/fixtures/files/api/beta/valid-test-data.json", "JSON", "", "application/json"

    specify "Sending a malformed JSON document should return a Bad Request status" do
      post "/api/beta/traits?key=3333333333333333333333333333333333333333", "{ no-closing-brace "
      aggregate_failures do
        expect(response.status).to eq 400
        expect(response.content_type).to eq "application/json"
        expect { Yajl::Parser.parse(response.body) }.to_not raise_exception
      end
      aggregate_failures do
        expect(Yajl::Parser.parse(response.body).keys).to match_array(['metadata', 'errors'])
        expect(Yajl::Parser.parse(response.body).fetch("errors")).to include("Request data is not a well-formed JSON document.")
      end
    end
  end

  # XML endpoint
  describe "XML:" do
    include_examples "format", "spec/fixtures/files/api/beta/valid-test-data.xml", "XML", ".xml", "application/xml"

    specify "Sending a malformed XML document should return a Bad Request status" do
      post "/api/beta/traits.xml?key=3333333333333333333333333333333333333333", "<no-closing-tag>"
      aggregate_failures do
        expect(response.status).to eq 400
        expect(response.content_type).to eq "application/xml"
        expect { Hash.from_xml(response.body) }.to_not raise_exception
      end
      aggregate_failures do
        expect(Hash.from_xml(response.body).fetch("hash").keys).to match_array(['metadata', 'errors'])
        expect(Hash.from_xml(response.body).fetch("hash").fetch("errors")).to include("Request data is not a well-formed XML document.")
      end
    end

    specify "Sending an invalid XML document should return a Bad Request status" do
      post "/api/beta/traits.xml?key=3333333333333333333333333333333333333333", "<xml-doc-not-conforming-to-schema/>"
      aggregate_failures do
        expect(response.status).to eq 400
        expect(response.content_type).to eq "application/xml"
        expect { Hash.from_xml(response.body) }.to_not raise_exception
      end
      aggregate_failures do
        expect(Hash.from_xml(response.body).fetch("hash").keys).to match_array(['metadata', 'errors'])
        expect(Hash.from_xml(response.body).fetch("hash").fetch("errors")).to have_key "schema_validation_errors"
      end
    end

  end

  # CSV endpoint
  describe "CSV:" do
    #include_examples "format", "spec/fixtures/files/api/beta/valid-test-data.csv", "CSV", ".csv", "application/xml"

    specify "Sending a CSV file that refers to missing meta-data should roll back the traits table" do

      expect {
        post "/api/beta/traits.csv?key=3333333333333333333333333333333333333333",
          File.open(Rails.root.join "spec/fixtures/files/api/beta/missing-meta-data.csv").read
      }.not_to change { Trait.count }

    end

    specify "Sending a CSV file that refers to missing meta-data should roll back the entities table" do

      expect {
        post "/api/beta/traits.csv?key=3333333333333333333333333333333333333333",
          File.open(Rails.root.join "spec/fixtures/files/api/beta/missing-meta-data.csv").read
      }.not_to change { Entity.count }

    end

    specify "Sending a CSV file that contains out-of-range trait values should roll back the entities table" do

      expect {
        post "/api/beta/traits.csv?key=3333333333333333333333333333333333333333",
          File.open(Rails.root.join "spec/fixtures/files/api/beta/out-of-range-data.csv").read
      }.not_to change { Entity.count }

    end

  end



#   context "via XML" do

#     before(:each) do
#       headers = {
#         "ACCEPT" => "application/xml",     # This is what Rails 4 accepts
#         "HTTP_ACCEPT" => "application/xml" # This is what Rails 3 accepts
#       }
#       post "/api/beta/traits.xml", { }, headers
#     end

#     specify "Posting to /api/beta/traits.xml should return a parsible XML response" do
#       expect(response.content_type).to eq("application/xml")
#       expect(Hash.from_xml(response.body)).to be_a Hash
#     end

#   end



#   # testing verbs

#   it "borks if given delete" do
#     delete "/api/beta/traits.xml", {}, {}

#     expect(response.status).to eq 401

#   end

# 1. A successful post should return a list of inserted traits, covariates, and
# entities including URIs for each created resource.  It should have actually
# done the insertions.

# 2. A post to a path of the form /api/* that isn't handled should return a 404
# status with an error message.

# 3. A post to a valid path but incorrect request method should return a 405
# status with an error message.

# 4. The response should have the correct Content-Type header.

# 5. Malformed data should generate the correct error message and return a 400
# status.

# 6. Altering the database shouldn't be allowed unless the user has creation permission.

end
