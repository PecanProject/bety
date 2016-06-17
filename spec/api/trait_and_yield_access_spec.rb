require 'spec_helper'

RSpec.describe "Trait GET API" do

  shared_examples "testing access levels" do |access_level|

    let(:apikey) { '4' * 36 + access_level.to_s * 4 }

    specify <<-MESSAGE do

        For users with a data access level of #{access_level}, traits having a
        data access level having a lower number shouldn't appear in the traits
        list unless they themselves created it

        MESSAGE

      get "/api/beta/traits.xml?key=#{apikey}"

      expect(response.body).to_not match(%r{<access-level type="integer">[1-#{access_level - 1}]</access-level>})

    end

      Trait.where("access_level < ?", access_level).each do |t|

    specify <<-MESSAGE do

        Users with a data access level of #{access_level} shouldn't be able to
        view traits having data access level #{t.access_level} unless they
        themselves created it
        MESSAGE


        get "/api/beta/traits/#{t.id}?key=#{apikey}"
        expect(response.body).not_to include('"trait"')
      
    end

      end

  end

  (2..4).each do |access_level|
    include_examples "testing access levels", access_level
  end

end
