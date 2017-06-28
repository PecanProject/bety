feature 'Citation index works' do

  context 'Visiting root_path' do
    it 'should result in current_path equaling "/"' do
      visit root_path
      
      expect(current_path).to eq '/'
    end
  end

end


