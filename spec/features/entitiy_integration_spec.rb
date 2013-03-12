require 'spec_helper'
include LoginHelper

feature 'Entities index works' do
  before :each do
    login_test_user
  end

  context 'GET /entities' do
    it 'should have "Listing entities" ' do
      visit '/entities'
      page.should have_content 'Listing entities'
    end

  end
end


