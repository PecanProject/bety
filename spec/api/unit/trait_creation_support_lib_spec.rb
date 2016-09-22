require 'spec_helper'

class EncapsulatedTraitCreationSupportModule
  include Api::TraitCreationSupport
  def initialize
    @new_trait_ids = []

    @schema_validation_errors = []
    @lookup_errors = []
    @model_validation_errors = []
    @database_insertion_errors = []
    @date_data_errors = []
  end




  # supply some things expected in the including class:
  def current_user
    return User.first
  end

  class Logger
    def debug(*args); end
  end

  def logger
    Logger.new
  end

end

RSpec.describe "Trait creation support library" do

  let(:ob) { EncapsulatedTraitCreationSupportModule.new }

  it "should do a database insertion when #create_traits_from_post_data is called with valid data" do
    expect {
      @result = ob.send(:create_traits_from_post_data, "<trait-data-set><trait mean='1' access_level='4' local_datetime='2001-04-06'><site sitename='Aliartos, Greece'/><variable name='SLA'/></trait></trait-data-set>")
    }.to change { Trait.count }.by 1
    expect(ob.instance_variable_get(:@schema_validation_errors)).to be_empty
  end

  it "should throw an XML::SyntaxError exception when the post data is not a well-formed XML document" do
    expect {
      @result = ob.send(:create_traits_from_post_data, "<trait-data-set><unclosedtag></trait-data-set>")
    }.to raise_error Nokogiri::XML::SyntaxError
  end

  it "should throw an InvalidDocument exception when the post data does not match the prescribed schema" do
    expect {
      @result = ob.send(:create_traits_from_post_data, "<trait-data-set><trait/></trait-data-set>")
    }.to raise_error Api::TraitCreationSupport::InvalidDocument
  end

  it "should throw an InvalidData exception and yield a lookup error when the specified variable doesn't match an existing variable" do
    expect {
      @result = ob.send(:create_traits_from_post_data, "<trait-data-set><trait mean='1' access_level='4'><variable name='bogus variable'/></trait></trait-data-set>")
    }.to raise_error Api::TraitCreationSupport::InvalidData

    expect(ob.instance_variable_get(:@lookup_errors).size).to eq(1)
  end

  it "should throw an InvalidData exception and set a model validation error when the value for the specified variable is out of range" do
    expect {
      @result = ob.send(:create_traits_from_post_data, "<trait-data-set><trait mean='-1' access_level='4'><variable name='SLA'/></trait></trait-data-set>")
    }.to raise_error Api::TraitCreationSupport::InvalidData

    expect(ob.instance_variable_get(:@model_validation_errors).size).to eq(1)
  end

  it "should throw an InvalidData exception and set a model date data error when a local_datetime is specified without specifying a site" do
    expect {
      @result = ob.send(:create_traits_from_post_data, "<trait-data-set><trait mean='1' access_level='4' local_datetime='2001-04-06'><variable name='SLA'/></trait></trait-data-set>")
    }.to raise_error Api::TraitCreationSupport::InvalidData

    expect(ob.instance_variable_get(:@date_data_errors).size).to eq(1)
  end

  it "should throw an InvalidData exception and set a model date data error when a local_datetime is specified and the specified site has a null time zone" do
    expect {
      @result = ob.send(:create_traits_from_post_data, "<trait-data-set><trait mean='1' access_level='4' local_datetime='2001-04-06'><site sitename='United Kingdom'/><variable name='SLA'/></trait></trait-data-set>")
    }.to raise_error Api::TraitCreationSupport::InvalidData

    expect(ob.instance_variable_get(:@date_data_errors).size).to eq(1)
  end

  it "should throw an InvalidData exception and set a model date data error when a local_datetime is specified as a default and the site is specified for a specific trait" do
    expect {
      @result = ob.send(:create_traits_from_post_data, "<trait-data-set><defaults local_datetime='2001-04-06'/><trait mean='1' access_level='4'><site sitename='Aliartos, Greece'/><variable name='SLA'/></trait></trait-data-set>")
    }.to raise_error Api::TraitCreationSupport::InvalidData

    expect(ob.instance_variable_get(:@date_data_errors).size).to eq(1)
  end

  it "should not throw an InvalidData exception when a local_datetime is specified as a default if the site is specified at the same level" do
    expect {
      @result = ob.send(:create_traits_from_post_data, "<trait-data-set><defaults local_datetime='2001-04-06'><site sitename='Aliartos, Greece'/></defaults><trait mean='1' access_level='4'><variable name='SLA'/></trait></trait-data-set>")
    }.not_to raise_error

    expect(ob.instance_variable_get(:@date_data_errors).size).to eq(0)
  end

end
