require 'spec_helper'

describe "treatments/index" do
  class ExtendedArray < Array
    def total_pages
      1
    end
  end
  before(:each) do
    assign(:treatments, [
      stub_model(Treatment),
      stub_model(Treatment)
    ])
    assign(:other_treatments, 
           ExtendedArray.new([
                 stub_model(Treatment),
                 stub_model(Treatment)
                ])
           )
  end

  it "renders a list of treatments" do
    render
    # Run the generator again with the --webrat flag if you want to use webrat matchers
  end
end
