require 'spec_helper'
include LoginHelper

feature 'Yields index works' do
  before :each do
    login_test_user
  end

  context 'GET /yields' do
    it 'should have "Listing yields" ' do
      visit '/yields'
      page.should have_content 'Listing yields'
    end

  end
end


