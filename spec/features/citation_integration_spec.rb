require 'support/helpers'
include LoginHelper

feature 'Citation features work' do
  before :each do
    login_test_user
  end

  context 'GET /citations/new', :type => :feature do
    it 'should have "New Citation" ' do
      visit '/citations/new'
      
      expect(page).to have_content 'New Citation'
    end

    it 'should allow creation of new citations' do
      visit '/citations/new'
      fill_in 'Author', :with => 'tester'
      fill_in 'Year', :with =>  '2009'
      fill_in 'Title', :with => 'ZOMG PAPER'
      fill_in 'Journal', :with =>  'Research Interwebs Papers'
      fill_in 'Vol', :with => '9999'
      fill_in 'Pg', :with => '9999'
      fill_in 'Url', :with =>  'http://www.reddit.com'
      click_button 'Create'
      
      expect(page).to have_content 'Citation was successfully created'

      # Apparently this forwards to the /sites/ ?
    end

  end

  context 'clicking view citation button' do
    it 'should return "Viewing Citation" ' do
      visit '/citations/'
      first(:xpath,".//a[@alt='show' and contains(@href,'/citations/')]").click
      expect(page).to have_content 'Viewing Citation'
    end
  end
  
  context 'Editing Citations' do

    before :each do
      visit '/citations/'
      first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
    end

    it 'should return "Editing Citation" ' do
      expect(page).to have_content 'Editing Citation'
    end

    it 'should allow adding a related site', js: true do
      click_link 'View Related Sites'
      fill_in 'search_sites', with: 'USA'
      click_link '+'
      click_button 'Update'
      # reopen related sites listing
      click_link 'View Related Sites'
      expect(page).to have_content 'USA'

      # now do clean-up:
      fill_in 'search_sites', with: 'USA'
      click_link 'X'
      click_button 'Update'
      # reopen related sites listing
      click_link 'View Related Sites'
      expect(page).not_to have_content 'USA'

  
    end

  end

  # test for Redmine bug #1921
  context 'editing the volume field of a citation' do
    it 'should change the value stored in the database and shown on the Show page' do
      visit '/citations/'
      # edit the first-listed citation
      first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
      first(:xpath, "//label[text() = 'Vol']/following-sibling::input[1]").set('1066')
      click_button 'Update'
      # In case the Show button doesn't work, go to the show page via the index:
      visit '/citations/'
      first(:xpath, "//a[@alt = 'show']").click
      expect(first(:xpath, "//div[@class = 'content']//dl/dd[preceding-sibling::dt[1][text() = 'Vol']]").text).to eq '1066'
    end
  end

  context 'clicking use citation button' do
    it 'should return "Sites already associated with this citation" ' do
      visit '/citations/'
      first(:xpath,".//a[@alt='use' and contains(@href,'/use_citation/')]").click
      expect(page).to have_content 'Sites already associated with this citation'
    end
  end

  context 'clicking use citation button for citation with no associated sites' do
    citation_with_no_sites = nil # make this available outside the block
    Citation.all.each do |c|
      if c.sites.size == 0
        citation_with_no_sites = c.id
        break
      end
    end
    it 'should list sites under the "Listing Sites" section of the Sites page' do
      visit '/citations/'
      first(:xpath,".//a[@alt='use' and contains(@href,'/use_citation/#{citation_with_no_sites}')]").click
      expect(page).to have_content 'Listing Sites'
      expect(page).not_to have_content 'No entries found'
    end
  end

end


