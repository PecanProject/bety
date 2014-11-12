require 'spec_helper'
include LoginHelper

feature 'Traits index works' do
  before :each do
    login_test_user
  end

  context 'GET /traits' do
    it 'should have "Listing Traits" ' do
      visit '/traits'
      page.should have_content 'Listing Traits'
    end

    context 'clicking view trait button' do
      it 'should return "Viewing Trait" ' do
        visit '/traits/'
        
        first(:xpath,".//a[@alt='show' and contains(@href,'/traits/')]").click
        page.should have_content 'Viewing Trait'
      end
    end

    context 'creating new trait' do
      it 'should not tell the user to choose a citation when trait creation fails for some other reason' do
        click_link 'Citations'
        first(:xpath,".//a[@alt='use' and contains(@href,'/use_citation/')]").click
        click_link 'Traits'
        click_link 'New Trait'
        
        page.should_not have_content 'Please choose a citation to work with first.'
      end
    end

    it 'should allow creation of new traits' do
     # Create Citation association
     visit '/citations'
     first(:xpath,".//a[@alt='use' and contains(@href,'/use_citation/')]").click
     page.should have_content 'Sites already associated with this citation'

     # Create Treatment association
     visit '/treatments'
     click_link 'New Treatment'
     fill_in 'Name', :with => 'Erduah'
     fill_in 'Definition', :with => 'Hot Earth'
     click_button 'Create'

     # Create Site association
     visit '/sites'
     click_link 'New Site'
     fill_in 'Site name', :with => 'Erduah'
     fill_in 'site_notes', :with => 'Hot Earth'
     click_button 'Create'


     # Verify the trait creation
     visit '/traits/new'
     
     page.should have_content 'New Trait'
     
     fill_in 'trait_mean', :with => '238.12'
     select 'SE', :from => 'trait_statname'
     fill_in 'trait_stat', :with => '7.76'
     fill_in 'trait_n', :with => '3'
     fill_in 'trait_notes', :with => 'Research Interwebs Papers Research Interwebs PapersResearch Interwebs PapersResearch Interwebs Papers' 

     click_button 'Create'
     
     page.should have_content 'Trait was successfully created'
    end


    
    context 'clicking edit trait button' do
      it 'should return "Editing Trait" ' do
        visit '/traits/'
        first(:xpath,".//a[@alt='edit' and contains(@href,'/edit')]").click
        page.should have_content 'Editing Trait'
      end
    end


  end
end

feature "Trait creation works" do

  before :each do
    login_test_user
    visit '/citations'
    first(:xpath, "//a[@alt = 'use']").click
    visit '/traits/new'
  end

  it "should complain that the mean wasn't specified if it is left blank" do
    click_button "Create"
    expect(page).to have_content "Mean can't be blank"
  end

  it "should not give a message about \"undefined method '<' for nil:NilClass\"", js:true do
    click_button "Create"
    expect(page).to_not have_content "undefined method `<' for nil:NilClass"
  end

  # Test for Redmine bug #2486:
  it "should not complain \"You have a nil object when you didn't expect it!\" if the create button is pressed twice" do
    click_button "Create"
    click_button "Create"
    expect(page).to_not have_content "You have a nil object when you didn't expect it!"
  end

end

feature "Editing traits works" do

  before :each do
    login_test_user
    visit '/traits/2/edit'
  end

  it "should complain that the mean wasn't specified if it is erased" do
    fill_in "trait_mean", with: ""
    click_button "Update"
    expect(page).to have_content "Mean can't be blank"
  end

  it "should not give a message about \"undefined method '<' for nil:NilClass\"" do
    fill_in "trait_mean", with: ""
    click_button "Update"
    expect(page).to_not have_content "undefined method `<' for nil:NilClass"
  end

  # Test for Redmine bug #2486:
  it "should not complain \"You have a nil object when you didn't expect it!\" if the update button is pressed twice" do
    fill_in "trait_mean", with: ""
    click_button "Update"
    click_button "Update"
    expect(page).to_not have_content "You have a nil object when you didn't expect it!"
  end

end
