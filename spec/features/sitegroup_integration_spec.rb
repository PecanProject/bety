require 'support/helpers'
include LoginHelper

# Override the default path "#{::Rails.root}/spec/fixtures"
RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/test/fixtures"
end

feature 'Authorization:' do

  fixtures :sitegroups

  let(:private_sitegroup) { sitegroups(:private_sitegroup) }

  let(:public_sitegroup) { sitegroups(:public_sitegroup) }

  context 'Even a Manager' do

    before :each do
      login_as_manager

      # find the user's name on the home page:
      current_user_name = first('#header_user_name').text.match(/Logged in as: (.*?) *$/)[1]

      # look up the current user's id:
      current_user_id = User.find_by_name(current_user_name).id

      # get all of this user's private sitegroups:
      @private_sitegroups_of_this_user = Sitegroup.where(user_id: current_user_id, public_access: false)

      # get all of this user's public sitegroups:
      @public_sitegroups_of_this_user = Sitegroup.where(user_id: current_user_id, public_access: true)

      # get all of this user's sitegroups:
      @sitegroups_of_this_user = @private_sitegroups_of_this_user + @public_sitegroups_of_this_user

      # get a list of private sitegroups of other users:
      @private_sitegroups_of_other_users = Sitegroup.where({public_access: false}).where("user_id != ?", current_user_id)

      # get a list of public sitegroups of other users:
      @public_sitegroups_of_other_users = Sitegroup.where({public_access: true}).where("user_id != ?", current_user_id)
    end

    specify "shouldn't see private sitegroups created by other users in the sitegroups list" do
      visit '/sitegroups'
      @private_sitegroups_of_other_users.each do |c|
        expect(page).not_to have_xpath ".//tbody/tr[td/text() = '#{c.name}']"
      end
    end

    specify "should see all public sitegroups and his own private sitegroups in the sitegroups list" do
      visit '/sitegroups'
      (@public_sitegroups_of_other_users + @sitegroups_of_this_user).each do |c|
        expect(page).to have_xpath ".//tbody/tr[td/text() = '#{c.name}']"
      end
    end

    specify "shouldn't be able to view private sitegroups of other users" do
      @private_sitegroups_of_other_users.each do |c|
        visit "/sitegroups/#{c.id}"
        expect(page).not_to have_content 'Viewing Site Group'
      end
    end

    specify "should be able to view private sitegroups of his own" do
      @private_sitegroups_of_this_user.each do |c|
        visit "/sitegroups/#{c.id}"
        expect(page).to have_content 'Viewing Site Group'
      end
    end

    specify "shouldn't see an edit button for a public sitegroup created by another user" do
      visit '/sitegroups'
      expect(page).not_to have_xpath('.//tr[td/text() = "public_sitegroup"][td/a[contains(@href, "/edit")]]')
    end

    # Ensure the previous test wasn't a false negative:
    specify "should see an edit button for a public sitegroup created by himself" do
      visit '/sitegroups'
      expect(page).to have_xpath('.//tr[td/text() = "creator_public_sitegroup"][td/a[contains(@href, "/edit")]]')
    end

    specify "shouldn't see a delete button for a public sitegroup created by another user" do
      visit '/sitegroups'
      expect(page).not_to have_xpath('.//tr[td/text() = "public_sitegroup"][td/a[@data-method = "delete"]]')
    end

    specify "shouldn't see an delete button even for a public sitegroup created by himself" do
      visit '/sitegroups'
      expect(page).not_to have_xpath('.//tr[td/text() = "creator_public_sitegroup"][td/a[@data-method = "delete"]]')
    end

    specify "shouldn't have edit access to even a public sitegroup created by another user" do
      skip "Restricting access to the edit pages for non-administrators" do
        visit "/sitegroups/#{public_sitegroup.id}/edit"
        expect(page).not_to have_content 'Editing Site Group'
      end
    end

    specify "shouldn't have delete permission for a sitegroup created by another user", type: :routing do
      expect { delete("/sitegroups/#{private_sitegroup.id}") }.to change { Sitegroup.count }.by 0
    end

  end

  context 'An Administrator' do

    before :each do
      login_test_user
    end

    specify "should see a sitegroups list containing all sitegroups" do
      visit '/sitegroups'
      expect(all(:xpath, ".//tbody/tr").length).to eq Sitegroup.count
    end

    specify "should see edit buttons for all items in the sitegroups list" do
      visit '/sitegroups'
      expect(all(:xpath, ".//tbody/tr[td/a[contains(@href, '/edit')]]").length).to eq Sitegroup.count
    end

    specify "should see delete buttons for all items in the sitegroups list" do
      visit '/sitegroups'
      expect(all(:xpath, ".//tbody/tr[td/a[@data-method = 'delete']]").length).to eq Sitegroup.count
    end

    specify "should be able to view private sitegroups created by other users" do
      sitegroup = sitegroups(:private_sitegroup_from_creator_user)
      id = sitegroup.id
      visit "/sitegroups/#{id}"
      expect(page).to have_content "Viewing Site Group"
      expect(page).to have_content sitegroup.name
    end

    specify "should have edit access to private sitegroups created by other users" do
      sitegroup = sitegroups(:private_sitegroup_from_creator_user)
      id = sitegroup.id
      visit "/sitegroups/#{id}/edit"
      expect(page).to have_content "Editing Site Group"
    end

    specify "should be able to edit private sitegroups created by other users" do
      sitegroup = sitegroups(:private_sitegroup_from_creator_user)
      id = sitegroup.id
      visit "/sitegroups/#{id}/edit"
      fill_in 'Name', with: 'my new name'
      click_button 'Update'
      expect(Sitegroup.find_all_by_name('my new name').count).to eq 1
    end

    specify "should be able to delete private sitegroups created by other users" do
      visit "/sitegroups"
      expect do
        first(:xpath, ".//tbody/tr[td/text() = 'creator_private_sitegroup']/td/a[@data-method = 'delete']").click
      end.to change { Sitegroup.count }.by(-1)
    end


  end


end
