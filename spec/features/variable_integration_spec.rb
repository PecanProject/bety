require 'spec_helper'
include LoginHelper

feature 'Variables index works' do
  before :each do
    login_test_user
  end

  context 'GET /variables' do
    it 'should have "Listing variables" ' do
      visit '/variables'
      page.should have_content 'Listing variables'
    end

  end
end


