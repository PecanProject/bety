 
describe "Signup page", :type => :request do
  describe "GET /signup"  do
    it "should return a valid response" do
      # Run the generator again with the --webrat flag if you want to use webrat methods/matchers
      get "/signup"
      expect(response.status).to be(200)
    end
  end
end
 
feature 'User creation works' do
  context 'GET /signup' do
    it 'should have "Sign up as a new user" ' do
      visit signup_path
      expect(page).to have_content("Sign up as a new user")
    end
    
    it 'should allow a user to be created' do
      visit signup_path
      fill_in 'user_login', :with =>  'winstonchurchill'
      fill_in 'user_email', :with =>  'winstonchurchill@gmail.com'
      fill_in 'user_password', :with =>  'asdfasdf'
      fill_in 'user_password_confirmation', :with =>  'asdfasdf'

      click_button 'Sign up'
      expect(page).to have_content("Thanks for signing up!")
    end

    it 'notify on password mismatch' do
      visit signup_path
      fill_in 'user_login', :with =>  'winstonchurchill'
      fill_in 'user_email', :with =>  'winstonchurchill@gmail.com'
      fill_in 'user_password', :with =>  'money'
      fill_in 'user_password_confirmation', :with =>  'notmoney'

      click_button 'Sign up'
      expect(page).to have_content("Password doesn't match confirmation")
    end
  end
end

