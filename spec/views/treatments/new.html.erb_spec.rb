
describe "treatments/new" do
  before(:each) do
    assign(:treatment, Treatment.new)
    assign(:current_user, User.new)
  end

  it "renders new treatment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", treatments_path, "post" do
    end
  end
end
