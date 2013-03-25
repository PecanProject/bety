require 'spec_helper'
 
feature 'Specie creation works' do
  context 'GET /species/new' do
    before :each do
      login_test_user
    end
  
    it 'should have "New species" ' do
      visit '/species/new'
      page.should have_content("New species")
    end
    
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

#    it 'notify on password mismatch' do
#      visit signup_path
#      fill_in 'user_login', :with =>  'winstonchurchill'
#      fill_in 'user_email', :with =>  'asdfasdf'
#      fill_in 'user_password', :with =>  'money'
#      fill_in 'user_password_confirmation', :with =>  'notmoney'

#      click_button 'Sign up'
#      page.should have_content("Password doesn't match confirmation")
#    end
  end
end

