require 'spec_helper'
include LoginHelper

feature 'Traits index works' do
  before :each do
    login_test_user
  end

  context 'GET /traits' do
    it 'should have "Listing traits" ' do
      visit '/traits'
      page.should have_content 'Listing traits'
    end

  end
end


