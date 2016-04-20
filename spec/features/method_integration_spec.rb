require 'support/helpers'
include LoginHelper

feature 'Methods index works' do
  before :each do
    login_test_user
  end

  context 'GET /methods' do
    it 'should have "Listing Methods" ' do
      visit '/methods'
      expect(page).to have_content 'Listing Methods'
    end

    it 'should allow creation of new methods' do
      visit '/methods/new'
      fill_in 'Name', :with =>'Zango'
      fill_in 'Description', :with => 'How to develop and implement biofuel crops in an ecologically and economically sustainable way requires evaluating'
      click_button 'Create'
      
      expect(page).to have_content 'Method was successfully created'
    end

    context 'clicking view method button' do
      it 'should return "Viewing Method" ' do
        visit '/methods/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/methods/')]").click
        expect(page).to have_content 'Viewing Method'
      end
    end
    
    context 'clicking edit method button' do
      it 'should return "Editing Method" ' do
        visit '/methods/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        expect(page).to have_content 'Editing Method'
      end
      it 'should return a edited field ' do
        visit '/methods/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click

        fill_in 'Name', :with =>'Barabaus_The_Bear'
        click_button 'Update'

        expect(page).to have_content 'Barabaus_The_Bear'
      end
    end

  end
end



