require "spec_helper"

describe ModelsController do
  describe "routing" do

    it "There is a route for GET /models/:id/edit_models_files" do
      expect(get("/models/1/edit_models_files")).to route_to("models#edit_models_files", id: "1")
    end

    it "There is a route for POST /models/:id/edit_models_files" do
      expect(post("/models/1/edit_models_files")).to route_to("models#edit_models_files", id: "1")
    end

  end
end

