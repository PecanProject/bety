# Override the default path "#{::Rails.root}/spec/fixtures"
RSpec.configure do |config|
  config.fixture_path = "#{::Rails.root}/test/fixtures"
end



describe "Trait" do

  fixtures :traits

  specify "Saving an unchanged trait shouldn't change it." do

    t = traits(:test_trait)

    # A bug having to do with method nsec is averted by using reload here:
    expect { t.save }.not_to change { t.updated_at }

  end

  specify "Saving an unchanged trait shouldn't change it, even if date attributes are inconsistent." do

    t = traits(:trait_with_inconsistent_date_attributes)

    # A bug having to do with method nsec is averted by using reload here:
    expect { t.save }.not_to change { t.updated_at }

  end

  context "Updating a non-date attribute of a trait having consistent date attributes" do

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

  context "Adding 1 to the d_year virtual attribute of a valid date should" do
    before(:example) do
      @trait = traits(:test_trait)
      @starting_d_year = @trait.d_year
      @trait.d_year += 1
    end

    it "increase the year by one" do
      expect { @trait.save; @trait.reload }.to change { @trait.date.year }.by(1)
    end

    it "not change the month" do
      expect { @trait.save; @trait.reload }.not_to change { @trait.date.month }
    end

    it "not change the day" do
      expect { @trait.save; @trait.reload }.not_to change { @trait.date.day }
    end

    it "not change the hour" do
      expect { @trait.save; @trait.reload }.not_to change { @trait.date.hour }
    end

    it "not change the minute" do
      expect { @trait.save; @trait.reload }.not_to change { @trait.date.min }
    end


    it "increase the year virtual attribute by one" do
      @trait.save
      @trait.reload
      expect(@trait.d_year - @starting_d_year).to eq(1)
    end

    it "not change the month virtual attribute" do
      expect { @trait.save; @trait.reload }.not_to change { @trait.d_month }
    end

    it "not change the day virtual attribute" do
      expect { @trait.save; @trait.reload }.not_to change { @trait.d_day }
    end

    it "not change the hour virtual attribute" do
      expect { @trait.save; @trait.reload }.not_to change { @trait.t_hour }
    end

    it "not change the minute virtual attribute" do
      expect { @trait.save; @trait.reload }.not_to change { @trait.t_minute }
    end

  end
end
