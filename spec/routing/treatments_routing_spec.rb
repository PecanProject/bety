require "spec_helper"

describe TreatmentsController do
  describe "routing" do

    it "routes to #index" do
      expect(get("/treatments")).to route_to("treatments#index")
    end

    it "routes to #new" do
      expect(get("/treatments/new")).to route_to("treatments#new")
    end

    it "routes to #show" do
      expect(get("/treatments/1")).to route_to("treatments#show", :id => "1")
    end

    it "routes to #edit" do
      expect(get("/treatments/1/edit")).to route_to("treatments#edit", :id => "1")
    end

    it "routes to #create" do
      expect(post("/treatments")).to route_to("treatments#create")
    end

    it "routes to #update" do
      expect(put("/treatments/1")).to route_to("treatments#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(delete("/treatments/1")).to route_to("treatments#destroy", :id => "1")
    end

  end
end
