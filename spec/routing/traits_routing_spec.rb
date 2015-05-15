require "spec_helper"

describe TraitsController do
  describe "routing" do

    specify "There is a route for GET /traits/trait_search." do
      expect(post("/traits/trait_search")).to route_to("traits#trait_search")
    end

    it "There is a route for GET /traits/unlink_covariate." do
      expect(get("/traits/2/unlink_covariate")).to route_to("traits#unlink_covariate", { id: "2" })
    end

  end
end
