# Override the default path "#{::Rails.root}/spec/fixtures"
RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/test/fixtures"
end



describe "Trait" do

  fixtures :traits

  xspecify "Saving an unchanged trait shouldn't change it." do

    t = traits(:test_trait)

    # A bug having to do with method nsec is averted by using reload here:
    expect { t.save }.not_to change { t.updated_at }

  end

  xspecify "Saving an unchanged trait shouldn't change it, even if date attributes are inconsistent." do

    t = traits(:trait_with_inconsistent_date_attributes)

    # A bug having to do with method nsec is averted by using reload here:
    expect { t.save }.not_to change { t.updated_at }

  end

  context "Updating a non-trait attribute of a trait having consistent date attributes" do

    before(:example) do
      @trait = traits(:test_trait)
      @trait.notes = "New note"
    end

    it "should save the change to the changed attribute" do
      @trait.save
      @trait.reload # ensure we get the saved version
      expect(@trait.notes).to eq("New note")
    end

    it "shouldn't change the date attribute" do
      # A bug having to do with method nsec is averted by using reload here:
      expect { @trait.save; @trait.reload }.not_to change { @trait.date }
    end

    it "shouldn't change the dateloc attribute" do
      # A bug having to do with method nsec is averted by using reload here:
      expect { @trait.save }.not_to change { @trait.dateloc }
    end

    it "shouldn't change the timeloc attribute" do
      expect { @trait.save }.not_to change { @trait.timeloc }
    end

  end

end
