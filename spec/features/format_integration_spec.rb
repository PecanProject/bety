require 'spec_helper'
include LoginHelper

feature 'Formats index works' do
  before :each do
    login_test_user
  end

  context 'GET /formats' do
    it 'should have "Listing formats" ' do
      visit '/formats'
      page.should have_content 'Listing formats'
    end

  end
end


