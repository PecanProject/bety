require 'spec_helper'
include LoginHelper

feature 'Citation index works' do
#  before :each do
#    login_test_user
#  end

  context 'GET /' do
    it 'should have "Welcome to BETYdb" ' do
      visit root_path
      
      expect(page).to have_content 'Welcome to BETYdb'
    end
  end

end


