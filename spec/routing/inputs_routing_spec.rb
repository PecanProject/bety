require "spec_helper"

describe InputsController do
  describe "routing" do

    it "There is a route for GET /inputs/edit_inputs_files" do
      expect(get("/inputs/edit_inputs_files")).to route_to("inputs#edit_inputs_files")
    end

    it "There is a route for GET /inputs/edit_inputs_variables" do
      expect(get("/inputs/edit_inputs_variables")).to route_to("inputs#edit_inputs_variables")
    end

    it "There is a route for POST /inputs/edit_inputs_files" do
      expect(post("/inputs/edit_inputs_files")).to route_to("inputs#edit_inputs_files")
    end

    it "There is a route for POST /inputs/edit_inputs_variables" do
      expect(post("/inputs/edit_inputs_variables")).to route_to("inputs#edit_inputs_variables")
    end

  end
end

