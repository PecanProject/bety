require 'spec_helper'
include LoginHelper

feature 'Citation index works' do
  before :each do
    login_test_user
  end

  context 'GET /citations/new', :type => :feature do
    it 'should have "New Citation" ' do
      visit '/citations/new'
      
      page.should have_content 'New Citation'
    end

    it 'should allow creation of new citations' do
      visit '/citations/new'
      fill_in 'Author', :with => 'tester'
      fill_in 'Year', :with =>  '2900'
      fill_in 'Title', :with => 'ZOMG PAPER'
      fill_in 'Journal', :with =>  'Research Interwebs Papers'
      fill_in 'Vol', :with => '9999'
      fill_in 'Pg', :with => '9999'
      fill_in 'Url', :with =>  'www.reddit.com'
      click_button 'Create'
      
      page.should have_content 'Citation was successfully created'

      # Apparently this forwards to the /sites/ ?
    end

    context 'clicking view citation button' do
      it 'should return "Viewing Citation" ' do
        visit '/citations/'
        first(:xpath,".//a[@alt='show' and contains(@href,'/citations/')]").click
        page.should have_content 'Viewing Citation'
      end
    end
    
    context 'clicking edit citation button' do
      it 'should return "Editing Citation" ' do
        visit '/citations/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        page.should have_content 'Editing Citation'
      end
    end

    context 'clicking use citation button' do
      it 'should return "Sites already associated with this citation" ' do
        visit '/citations/'
        first(:xpath,".//a[@alt='use' and contains(@href,'/use_citation/')]").click
        page.should have_content 'Sites already associated with this citation'
      end
    end

    context 'clicking use citation button for citation with no associated sites' do
      Citation.all.each do |c|
        if c.sites.size == 0
          citation_with_no_sites = c.id
          break
        end
      end
      it 'should list sites under the "Listing Sites" section of the Sites page' do
        visit '/citations/'
        first(:xpath,".//a[@alt='use' and contains(@href,'/use_citation/#{citation_with_no_sites}')]").click
        page.should have_content 'Listing Sites'
        page.should_not have_content 'No entries found'
      end
    end

  end
end


