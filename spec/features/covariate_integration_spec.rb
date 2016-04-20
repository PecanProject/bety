require 'support/helpers'
include LoginHelper

feature 'Covariate pages work' do
  before :each do
    login_test_user
  end

  context 'GET /covariates' do
    it 'should have "Listing Covariates" ' do
      visit '/covariates'
      expect(page).to have_content 'Listing Covariates'
    end
  end

  specify 'Individual covariates should be editable' do
    visit '/covariates'
    first(:xpath, ".//a[@alt = 'edit']").click
    expect(page).to have_content 'Editing covariate'
  end

end


