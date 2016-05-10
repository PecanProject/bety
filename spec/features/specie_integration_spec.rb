require 'support/helpers'
include LoginHelper

feature 'Species pages work' do
  before :each do
    login_test_user
  end

  context 'GET /species' do
    it 'should have "Listing Species" ' do
      visit '/species'
      expect(page).to have_content 'Listing Species'
    end
  end

  context 'GET /species/new' do
    it 'should have "New Species" ' do
      visit '/species/new'
      expect(page).to have_content("New Species")
    end
  end
  
  context 'GET /species/new' do
    it 'should allow a specie to return success notification' do
      visit '/species/new'
      
      fill_in 'specie[spcd]', :with =>  '555'
      fill_in 'specie[genus]', :with =>  'Asdfasdf'
      fill_in 'specie[species]', :with =>  'asdfasdf'
      fill_in 'specie[scientificname]', :with =>  'Asdfasdf asdfasdf'
      fill_in 'specie[commonname]', :with =>  'winstonchurchill'
      fill_in 'specie[AcceptedSymbol]', :with =>  'asdfasdf'
      fill_in 'specie[SynonymSymbol]', :with =>  'asdfasdf'
      fill_in 'specie[Symbol]', :with =>  'asdfasdf'
      fill_in 'specie[PLANTS_Floristic_Area]', :with =>  'winstonchurchill'
      fill_in 'specie[State]', :with =>  'asdfasdf'
      fill_in 'specie[Category]', :with =>  'asdfasdf'
      fill_in 'specie[Family]', :with =>  'asdfasdf'
      fill_in 'specie[FamilySymbol]', :with =>  'asdfasdf'
      fill_in 'specie[FamilyCommonName]', :with =>  'asdfasdf'
      fill_in 'specie[xOrder]', :with =>  'asdfasdf'
      fill_in 'specie[SubClass]', :with =>  'asdfasdf'
      fill_in 'specie[Class]', :with =>  'asdfasdf'
      
      
      click_button 'Create'
      expect(page).to have_content("Specie was successfully created.")
    end
  end

  context 'GET /species/edit/:id' do
    it 'should allow editing a species' do
      visit '/species'
      first(:xpath, './/a[@alt = "edit"]').click
      expect(page).to have_content 'Editing Species'
    end
  end


end


