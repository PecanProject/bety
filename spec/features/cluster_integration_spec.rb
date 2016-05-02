require 'support/helpers'
include LoginHelper

# Override the default path "#{::Rails.root}/spec/fixtures"
RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/test/fixtures"
end

feature 'Authorization:' do

  fixtures :clusters

  let(:private_cluster) { clusters(:private_cluster) }

  let(:public_cluster) { clusters(:public_cluster) }

  context 'Even a Manager' do

    before :each do
      login_as_manager

      # find the user's name on the home page:
      current_user_name = first('#header_user_name').text.match(/Logged in as: (.*?) *$/)[1]

      # look up the current user's id:
      current_user_id = User.find_by_name(current_user_name).id

      # get all of this user's private clusters:
      @private_clusters_of_this_user = Cluster.where(user_id: current_user_id, everybody: false)

      # get all of this user's public clusters:
      @public_clusters_of_this_user = Cluster.where(user_id: current_user_id, everybody: true)

      # get all of this user's clusters:
      @clusters_of_this_user = @private_clusters_of_this_user + @public_clusters_of_this_user

      # get a list of private clusters of other users:
      @private_clusters_of_other_users = Cluster.where({everybody: false}).where("user_id != ?", current_user_id)

      # get a list of public clusters of other users:
      @public_clusters_of_other_users = Cluster.where({everybody: true}).where("user_id != ?", current_user_id)
    end

    specify "shouldn't see private clusters created by other users in the clusters list" do
      visit '/clusters'
      @private_clusters_of_other_users.each do |c|
        expect(page).not_to have_xpath ".//tbody/tr[td/text() = '#{c.name}']"
      end
    end

    specify "should see all public clusters and his own private clusters in the clusters list" do
      visit '/clusters'
      (@public_clusters_of_other_users + @clusters_of_this_user).each do |c|
        expect(page).to have_xpath ".//tbody/tr[td/text() = '#{c.name}']"
      end
    end

    specify "shouldn't be able to view private clusters of other users" do
      @private_clusters_of_other_users.each do |c|
        visit "/clusters/#{c.id}"
        expect(page).not_to have_content 'Viewing Cluster'
      end
    end

    specify "should be able to view private clusters of his own" do
      @private_clusters_of_this_user.each do |c|
        visit "/clusters/#{c.id}"
        expect(page).to have_content 'Viewing Cluster'
      end
    end

    specify "shouldn't see an edit button for a public cluster created by another user" do
      visit '/clusters'
      expect(page).not_to have_xpath('.//tr[td/text() = "public_cluster"][td/a[contains(@href, "/edit")]]')
    end

    # Ensure the previous test wasn't a false negative:
    specify "should see an edit button for a public cluster created by himself" do
      visit '/clusters'
      expect(page).to have_xpath('.//tr[td/text() = "creator_public_cluster"][td/a[contains(@href, "/edit")]]')
    end

    specify "shouldn't see a delete button for a public cluster created by another user" do
      visit '/clusters'
      expect(page).not_to have_xpath('.//tr[td/text() = "public_cluster"][td/a[@data-method = "delete"]]')
    end

    specify "shouldn't see an delete button even for a public cluster created by himself" do
      visit '/clusters'
      expect(page).not_to have_xpath('.//tr[td/text() = "creator_public_cluster"][td/a[@data-method = "delete"]]')
    end

    specify "shouldn't have edit access to even a public cluster created by another user" do
      visit "/clusters/#{public_cluster.id}/edit"
      expect(page).not_to have_content 'Editing Cluster'
    end

    specify "shouldn't have delete permission for a cluster created by another user", type: :routing do
      expect { delete("/clusters/#{private_cluster.id}") }.to change { Cluster.count }.by 0
    end

  end

  context 'An Administrator' do

    before :each do
      login_test_user
    end

    specify "should see a clusters list containing all clusters" do
      visit '/clusters'
      expect(all(:xpath, ".//tbody/tr").length).to eq Cluster.count
    end

    specify "should see edit buttons for all items in the clusters list" do
      visit '/clusters'
      expect(all(:xpath, ".//tbody/tr[td/a[contains(@href, '/edit')]]").length).to eq Cluster.count
    end

    specify "should see delete buttons for all items in the clusters list" do
      visit '/clusters'
      expect(all(:xpath, ".//tbody/tr[td/a[@data-method = 'delete']]").length).to eq Cluster.count
    end

    specify "should be able to view private clusters created by other users" do
      cluster = clusters(:private_cluster_from_creator_user)
      id = cluster.id
      visit "/clusters/#{id}"
      expect(page).to have_content "Viewing Cluster"
      expect(page).to have_content cluster.name
    end

    specify "should have edit access to private clusters created by other users" do
      cluster = clusters(:private_cluster_from_creator_user)
      id = cluster.id
      visit "/clusters/#{id}/edit"
      expect(page).to have_content "Editing Cluster"
    end

    specify "should be able to edit private clusters created by other users" do
      cluster = clusters(:private_cluster_from_creator_user)
      id = cluster.id
      visit "/clusters/#{id}/edit"
      fill_in 'Name', with: 'my new name'
      click_button 'Update'
      expect(Cluster.find_all_by_name('my new name').count).to eq 1
    end

    specify "should be able to delete private clusters created by other users" do
      visit "/clusters"
      expect do
        first(:xpath, ".//tbody/tr[td/text() = 'creator_private_cluster']/td/a[@data-method = 'delete']").click
      end.to change { Cluster.count }.by(-1)
    end


  end


end


      
