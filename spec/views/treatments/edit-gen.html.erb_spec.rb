
describe "treatments/edit" do
  before(:each) do
    @treatment = assign(:treatment, Treatment.first)
    assign(:management, Management.new)
    assign(:current_user, User.new)
  end

  it "renders the edit treatment form" do
    render

    # Run the generator again with the --webrat flag if you want to use webrat matchers
    assert_select "form[action=?][method=?]", treatment_path(@treatment), "post" do
    end
  end
end
