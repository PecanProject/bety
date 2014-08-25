require 'spec_helper'
include LoginHelper

feature 'Ensembles work' do
  before :each do
    login_test_user
  end

  context 'GET /ensembles' do
    it 'should have "Listing Ensembles" ' do
      visit '/ensembles'
      page.should have_content 'Listing Ensembles'
    end

    it 'should not have "New Ensemble" page ' do
      expect { visit '/ensembles/new' }.to raise_error
    end

    it 'should not have "Edit Ensemble" page ' do
      expect { visit '/ensembles/edit/1' }.to raise_error
    end

    context 'clicking view ensemble button' do
      it 'should return "Viewing Ensemble" ' do
        visit '/ensembles/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/ensembles/')]").click
        page.should have_content 'Viewing Ensemble'
      end
    end
  end
end

