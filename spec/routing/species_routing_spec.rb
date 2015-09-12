require "spec_helper"

describe SpeciesController do
  describe "routing" do

    it "routes the species removal action" do
      expect(get("/species/rem_pfts_species")).to route_to("species#rem_pfts_species")
    end

    it "routes the the edit associated pfts action" do
      expect(get("/species/add_pfts_species")).to route_to("species#add_pfts_species")
    end

    it "routes the species search action" do
      expect(post("/species/species_search")).to route_to("species#species_search")
    end

  end
end
