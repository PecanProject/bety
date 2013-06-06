require 'spec_helper'
include LoginHelper

feature 'Species index works' do
  before :each do
    login_test_user
  end

  context 'GET /species' do
    it 'should have "Listing Species" ' do
      visit '/species'
      page.should have_content 'Listing Species'
    end
  end

  context 'GET /species/new' do
    it 'should have "New Species" ' do
      visit '/species/new'
      page.should have_content("New Species")
    end
  end
  
  context 'GET /species/new' do
    it 'should allow a specie to return success notification' do
      visit '/species/new'
      
      fill_in 'specie[spcd]', :with =>  'winstonchurchill'
      fill_in 'specie[genus]', :with =>  'asdfasdf'
      fill_in 'specie[species]', :with =>  'asdfasdf'
      fill_in 'specie[scientificname]', :with =>  'asdfasdf'
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
      page.should have_content("Specie was successfully created.")
    end
  end

end


