require 'spec_helper'
include LoginHelper

feature 'Priors index works' do
  before :each do
    login_test_user
  end

  context 'GET /priors' do
    it 'should have "Listing priors" ' do
      visit '/priors'
      page.should have_content 'Listing priors'
    end

  end
end


