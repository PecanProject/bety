# the test for the work_flow page

require 'support/helpers'
include LoginHelper

feature 'Work_flow index works' do
  before :each do
    login_test_user
  end

  subject { page}
  context 'GET /workflows' do
    it 'should have "Listing Workflows" ' do
      visit workflows_path
      expect(page).to have_content 'Listing Workflows'
    end
  end

  # test for the Listing Inputs
  describe ' click on input link' do
    it ' should have "Listing Inputs" ' do
      visit '/users'
      click_link('Inputs')
      expect(page).to have_content 'Listing Inputs'
    end
  end
end
