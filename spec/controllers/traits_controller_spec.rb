describe TraitsController do
	let(:session) {
		{user_id: 512127716}
	}
	let(:valid_attr){
		{:mean => '2'}
	}
  let(:invalid_attr){
    {:mean => "-1",:stat => "a"}
  }
  let(:valid_covariate){
    [{'variable_id' => '404','level' =>'10'}]
  }
  let(:invalid_covariate){
    [{'variable_id' => '404','level' =>'50'}]
  }
  let(:mixed_covariate){
    [{'variable_id' => '404','level' =>'50'},{'variable_id' => '2','level' =>'10'}]
  }

	context'message on invalid input' do
    it 'should not return success message' do
			trait = Trait.find_by_id('2')
	    post :update,{:id =>trait.to_param,:trait => invalid_attr},session
	    assert_not_equal(flash[:notice], "Trait was successfully updated.")
	  end

    it 'should return error message' do
	    trait = Trait.find_by_id('2')
	    post :update,{:id =>trait.to_param,:covariate => invalid_covariate},session
	    assert_not_nil flash[:error]
	  end
	end

  context "record should not be modified with invalid input" do
    before :each do
      @trait = Trait.find_by_id('2')
    end

    it 'should not modify attribute if covariate is invalid' do
	    post :update,{:id =>@trait.to_param, :covariate => invalid_covariate, :trait =>valid_attr},session
      new_trait = Trait.find_by_id('2')
      assert_equal(@trait.mean, new_trait.mean)
    end

    it 'should not modify covariate list if attribute is invalid' do
      old_size = @trait.covariates.size
	    post :update,{:id =>@trait.to_param, :covariate => valid_covariate, :trait => invalid_attr},session
      new_trait = Trait.find_by_id('2')
      assert_equal(old_size, new_trait.covariates.size)
    end

    it 'should not modify covariate list if any covariate is invalid' do
      old_size = @trait.covariates.size
	    post :update,{:id =>@trait.to_param, :covariate => mixed_covariate, :trait =>valid_attr},session
      new_trait = Trait.find_by_id('2')
      assert_equal(old_size, new_trait.covariates.size)
    end
  end

  context "after submission of invalid input" do
    render_views
    before :each do
      @trait = Trait.find_by_id('2')
    end

    it "should render edit action" do
	    post :update,{:id =>@trait.to_param,:trait => invalid_attr},session
	    assert_template 'edit', "Failed to render edit action"
    end

    it "should display error messages" do
	    post :update,{:id =>@trait.to_param,:trait => invalid_attr},session
	    expect(response.body).to have_content("2 errors")
    end

    it "should not change attribute inputs" do
	    post :update,{:id =>@trait.to_param,:trait => invalid_attr},session
      expect(response.body).to have_selector("input#trait_mean[value = '#{invalid_attr[:mean]}']")
    end

    it "should not change covariate inputs" do
	    post :update,{:id =>@trait.to_param,:trait => invalid_attr, :covariate =>invalid_covariate},session
	    expect(response.body).to have_xpath(".//select[@id='covariate__variable_id']/option[@value='404' and @selected='selected']")
    end
  end

end
