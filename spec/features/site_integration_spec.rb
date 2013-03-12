require 'spec_helper'
include LoginHelper

feature 'Sites index works' do
  before :each do
    login_test_user
  end

  context 'GET /sites' do
    it 'should have "Listing sites" ' do
      visit '/sites'
      page.should have_content 'Listing sites'
    end

  end
end


