require 'spec_helper'

describe "treatments/new" do
  before(:each) do
    assign(:treatment, stub_model(Treatment).as_new_record)
    assign(:current_user, stub_model(User).as_new_record)
  end

  it "renders new treatment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", treatments_path, "post" do
    end
  end
end
