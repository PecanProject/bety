require 'spec_helper'
include LoginHelper

feature 'Pfts index works' do
  before :each do
    login_test_user
  end

  context 'GET /pfts' do
    it 'should have "Listing pfts" ' do
      visit '/pfts'
      page.should have_content 'Listing pfts'
    end

  end
end


