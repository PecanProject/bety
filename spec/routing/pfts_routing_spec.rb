require "spec_helper"

describe PftsController do
  describe "routing" do

    it "allows posting to /pfts/1/edit2_pfts_species" do
      expect(post("/pfts/1/edit2_pfts_species")).to route_to("pfts#edit2_pfts_species", { "id" => "1" })
    end

    it "allows getting /pfts/1/edit2_pfts_species" do
      expect(get("/pfts/1/edit2_pfts_species")).to route_to("pfts#edit2_pfts_species", { "id" => "1" })
    end


  end
end

