require 'spec_helper'
include LoginHelper

feature 'Species index works' do
  before :each do
    login_test_user
  end

  context 'GET /species' do
    it 'should have "Listing Species" ' do
      visit '/species'
      page.should have_content 'Listing Species'
    end

  end
end


