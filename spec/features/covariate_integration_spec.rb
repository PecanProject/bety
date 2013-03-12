require 'spec_helper'
include LoginHelper

feature 'Covariates index works' do
  before :each do
    login_test_user
  end

  context 'GET /covariates' do
    it 'should have "Listing covariates" ' do
      visit '/covariates'
      page.should have_content 'Listing covariates'
    end

  end
end


