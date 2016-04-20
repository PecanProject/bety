
describe SessionsController do

  describe "GET 'login'" do
    it "should be successful" do
      get 'create'
      expect(response).to be_success
    end
#    it "should have 'Log In'" do
#      get 'create'
#      puts "####"
#      puts response
#      response.should have_content('Log In')
##      response.should have_selector("title", :content => "Energy Biosciences Institute")
##      page.should have_selector(:xpath, '//table/tr')
#    end
#    it 'welcomes the user' do
#      visit '/'
#      page.should have_content('Welcome')
#    end

  end
  
  describe "POST 'create'" do
#    before(:each) do
#      get 'create'
#      @attr = { :login => "carlcrott", :password => "asdfasdf" }
#    end
#    

#  describe "Home page" do

#    it "should have the content 'Sample App'" do
#      visit '/static_pages/home'
#      page.should have_content('Sample App')
#    end
#  end
    
#    describe 'blog post page' do
#      it 'lets the user post a comment', :js => true do
#        visit '/login'
##        visit login_path
##        fill_in 'login', :with => 'carlcrott'
##        fill_in 'password', :with => 'asdfasdf'
##        click_on 'Login'  # this be an Ajax button -- requires Selenium
#        page.should have_content('New to BETYdb?')
#        page.should have_selector('h1', text: "Log In")
##        page.should have_content('Awesome post!')
##        flash[:notice].should =~ /Logged in successfully/i
#      end
#    end
    
    
    
#    describe "success" do
#      it "should create a new session" do
#        post :create, :sessions => @attr
#        response.should have_css("div#flash_notice")
##        response.should have_text("Logged in successfully")
##        flash[:notice].should =~ /Logged in successfully/i
#      end
#    end

#      it "should confirm successful login" do
#        flash[:notice].should =~ "Logged in successfully"
#      end
    
      
#      it "should be successful" do
#        get 'create'
#        response.should be_success
#      end
    

  
  end

  describe "invalid signin" do

    before(:each) do
      @attr = { :email => "email@example.com", :password => "invalid" }
    end

    it "should re-render the new page" do
      post :create, :session => @attr
      expect(response).to render_template('new')
    end

#    it "should have the right title" do
#      post :create, :session => @attr
#      response.should have_selector("title", :content => "Sign in")
#    end

#    it "should have a flash.now message" do
#      post :create, :session => @attr
#      flash.now[:error].should =~ /invalid/i
#    end
  end


end
