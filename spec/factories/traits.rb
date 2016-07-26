FactoryGirl.define do
  factory :trait do
    site
    mean 1
    variable
    access_level 4

    factory :trait_with_inconsistent_date_attributes do

      date "2005-07-25 09:31:00"
      dateloc 9
      timeloc 9

    end

    factory :trait_with_consistent_date_attributes do

      date "2005-07-25 09:31:35"
      dateloc 5
      timeloc 1

    end

  end
end
