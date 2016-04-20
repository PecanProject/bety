feature 'Citation index works' do

  context 'GET /' do
    it 'should have "Welcome to BETYdb" ' do
      visit root_path
      
      expect(page).to have_content 'Welcome to BETYdb'
    end
  end

end


