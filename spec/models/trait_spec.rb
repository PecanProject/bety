require 'spec_helper'

### SAMPLE DATA ###

# samples for all possible dateloc values
TEST_DATE_SAMPLES = [
                     { dateloc: 9, date_attributes: {}, description: "no date information is given" },
                     { dateloc: 8, date_attributes: { d_year: 2001 }, description: "only a year is given" },
                     { dateloc: 7, date_attributes: { d_year: 2001, d_month: "Season: SON" }, description: "a year and season are given" },
                     { dateloc: 6, date_attributes: { d_year: 2001, d_month: 7 }, description: "a year and month are given" },
                     { dateloc: 5, date_attributes: { d_year: 2001, d_month: 7, d_day: 23 }, description: "a year, month, and day are given" },
                     { dateloc: 97, date_attributes: { d_month: "Season: DJF" }, description: "only a season is given" },
                     { dateloc: 96, date_attributes: { d_month: 11 }, description: "only a month is given" },
                     { dateloc: 95, date_attributes: { d_month: 11, d_day: 9 }, description: "only a month and day are given"  }
                    ]

TEST_SITES = [
              { site_id: 1 },
              { site_id: 2 },
              { site_id: 3 },
              { site_id: 4 }
]

ABERRANT_DATA = [
                 { dateloc: nil, description: "no dateloc is given" },
                 { dateloc: 5.5, description: "the obsolescent week dateloc is given" },
                 { dateloc: 10, description: "an invalid dateloc is given" }
]

### CONVENIENCE METHODS ###

# Compare result of calling Trait#pretty_print with calling the PL/pgSQL
# function pretty_print.  (The latter comprises the normative interpretation of
# trait date/dateloc information.)
def rails_pp_output_agrees_with_sql_pp_output(t)
  sql_call = "SELECT pretty_date(date, dateloc, timeloc, site_id) FROM traits WHERE id = #{t.id}"
  
  sql_text = ActiveRecord::Base.connection.select_all(sql_call).first.fetch("pretty_date")
  rails_text = t.pretty_date
  
  expect(sql_text).to eq(rails_text), <<MSG

       With trait = #{t.inspect},

       expected: "#{sql_text}"
            got: "#{rails_text}"

MSG

end

# Add an attribute that lets us skip the before_save callback
class Trait
  attr_accessor :raw_update
  skip_callback :save, :before, :process_datetime_input, if: -> { self.raw_update }
end


### TESTS ###


describe "Trait" do
  describe "basic validity constraints" do
    it 'should be invalid if no attributes are given' do

      t = Trait.new
      t.invalid?.should == true
    end

    it 'should be valid if a valid mean, variable_id, site_id, and access_level are given' do
      t = Trait.new mean: 6, access_level: 1, variable_id: 1, site_id: 1
      t.invalid?.should == false
    end
  end # describe "basic validity constraints"

  describe "date and time semantics" do
    let(:sample_trait) do
      Trait.create mean: 1, variable_id: 1, access_level: 1, site_id: 1
    end

    describe "automatic dateloc setting" do
      TEST_DATE_SAMPLES.each do |sample|
        it "should set dateloc to #{sample.fetch(:dateloc)} if #{sample.fetch(:description)}" do
          sample_trait.update_attributes(sample.fetch(:date_attributes))
          expect(sample_trait.dateloc).to eq sample.fetch(:dateloc)
        end
      end
    end

    describe "pretty-printing date should pretty print the date and time according to the normative SQL function" do

      TEST_DATE_SAMPLES.each do |sample_date|
        TEST_SITES.each do |sample_site|
          it "when #{sample_date.fetch(:description)} and site timezone is #{Site.find(sample_site.fetch(:site_id)).time_zone || 'nil'}" do

            # set the site first so that timezone is taken into consideration when date is set
            sample_trait.update_attributes(sample_site)

            sample_trait.update_attributes(sample_date.fetch(:date_attributes))

            rails_pp_output_agrees_with_sql_pp_output(sample_trait)

          end # end it
        end # inner each loop
      end # outer each loop

      describe "pretty_date should display aberrant date information according to the normative SQL function" do
        let(:sample_trait_with_date) do
          t = Trait.create(mean: 1, variable_id: 1, access_level: 1, site_id: 1, d_year: 2001, d_month: 7, d_day: 23)
          t.raw_update = true # circumvent before_save callback so we can set dateloc at will
          return t
        end # let

        ABERRANT_DATA.each do |facet|
          it "when #{facet.fetch(:description)}" do
            sample_trait_with_date.update_attributes(dateloc: facet.fetch(:dateloc))

            rails_pp_output_agrees_with_sql_pp_output(sample_trait_with_date)
          end
        end # ABERRANT_DATA.each
      end # describe "aberrant cases"

    end # describe "pretty-printing date"

  end # describe "date and time semantics"
end # describe "Trait"
