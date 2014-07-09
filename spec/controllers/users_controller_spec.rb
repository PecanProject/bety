require 'spec_helper'

describe UsersController do

#  describe "GET 'login'" do
#    it "should be successful" do
#      get 'create'
#      response.should be_success
#    end
#  end
#  

#  
#  context 'User login with captcha' do
#    it 'should login with correct recaptcha' do
#      SessionsController.any_instance.expects(:verify_recaptcha).returns(true)
#      post :login, { :username => "carlcrott", :password => "asdfasdf" }
#      session[:user].should eql(user.id)
#      response.should redirect_to(root_path)
#    end
#  end

=begin	
  	subject { page }

	describe " click on the data link" do
		it 'should contains the link of user page' do
		 	visit root_path
		 	click_link "Users"
		 	expect(page).to have_title("Listing Users")

		end
	end
=end


=begin
	describe "	users with access equal to 1" do
		it ' should see more than 1 users in list' do
			current_user = User.new
			expect(current_user.find(test_user3.id).length) >2
		
		#test for administrator
		end
	end

	describe " users with access greater than 1" do
		it ' should only show his own page ' do
			current_user = User.new
			expect(current_user.find(test_user1.id).length) =1

			# test for visitor	end
	end

 	describe " users with access greater than 1" do
 		it ' show see more than 1 users in list ' do
 			current_user = User.new
 			expect(current_user.find(test_user4.id).length) >2

 		#test for administrator
 		end
 	end
=end

end
