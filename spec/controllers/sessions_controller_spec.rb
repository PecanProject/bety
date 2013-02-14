require 'spec_helper'

describe SessionsController do

  describe "GET 'login'" do
    it "should be successful" do
      get 'create'
      response.should be_success
    end
  end


end
