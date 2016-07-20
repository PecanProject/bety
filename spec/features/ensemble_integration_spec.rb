require 'support/helpers'
include LoginHelper

feature 'Ensembles work' do
  before :each do
    login_test_user
  end

  context 'GET /ensembles' do
    it 'should have "Listing Ensembles" ' do
      visit '/ensembles'
      expect(page).to have_content 'Listing Ensembles'
    end

    # to-do: move this to a routing spec
    it 'should not have "New Ensemble" page ' do
      expect { visit '/ensembles/new' }.to raise_error AbstractController::ActionNotFound
    end

    # to-do: move this to a routing spec
    it 'should not have "Edit Ensemble" page ' do
      expect { visit '/ensembles/edit/1' }.to raise_error ActionController::RoutingError
    end

    context 'clicking view ensemble button' do
      it 'should return "Viewing Ensemble" ' do
        visit '/ensembles/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/ensembles/')]").click
        expect(page).to have_content 'Viewing Ensemble'
      end
    end
  end
end

