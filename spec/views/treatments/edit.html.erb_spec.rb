require 'spec_helper'

describe "treatments/edit" do
  before(:each) do
    @treatment = assign(:treatment, stub_model(Treatment))
    assign(:management, stub_model(Management))
    assign(:current_user, stub_model(User))
  end

  it "renders the edit treatment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", treatment_path(@treatment), "post" do
    end
  end
end
