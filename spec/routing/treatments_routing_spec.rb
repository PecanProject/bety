require "spec_helper"

describe TreatmentsController do
  describe "routing" do

    it "routes to #index" do
      get("/treatments").should route_to("treatments#index")
    end

    it "routes to #new" do
      get("/treatments/new").should route_to("treatments#new")
    end

    it "routes to #show" do
      get("/treatments/1").should route_to("treatments#show", :id => "1")
    end

    it "routes to #edit" do
      get("/treatments/1/edit").should route_to("treatments#edit", :id => "1")
    end

    it "routes to #create" do
      post("/treatments").should route_to("treatments#create")
    end

    it "routes to #update" do
      put("/treatments/1").should route_to("treatments#update", :id => "1")
    end

    it "routes to #destroy" do
      delete("/treatments/1").should route_to("treatments#destroy", :id => "1")
    end

  end
end
