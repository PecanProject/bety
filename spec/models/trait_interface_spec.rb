# Override the default path "#{::Rails.root}/spec/fixtures"
RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/test/fixtures"
end



describe "Trait" do

  fixtures :traits

  specify "Saving an unchanged trait shouldn't change it, even if date attributes are inconsistent." do

    t = traits(:trait_with_inconsistent_date_attributes)

    # A bug having to do with method nsec is averted by using reload here:
    expect { t.save; t.reload }.not_to change { t.date }

  end

end
