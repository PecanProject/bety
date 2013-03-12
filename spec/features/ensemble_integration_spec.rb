require 'spec_helper'
include LoginHelper

feature 'Ensembles index works' do
  before :each do
    login_test_user
  end

  context 'GET /ensembles' do
    it 'should have "Listing ensembles" ' do
      visit '/ensembles'
      page.should have_content 'Listing ensembles'
    end

  end
end


