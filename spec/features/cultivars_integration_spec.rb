require 'spec_helper'
include LoginHelper

feature 'Cultivars index works' do
  before :each do
    login_test_user
  end

  context 'GET /cultivars' do
    it 'should have "Listing cultivars" ' do
      visit '/cultivars'
      page.should have_content 'Listing cultivars'
    end

  end
end
