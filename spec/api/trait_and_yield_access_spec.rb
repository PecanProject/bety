require 'spec_helper'

RSpec.describe "Trait GET API" do

  shared_examples "testing access levels" do |access_level|

    let(:apikey) { '4' * 36 + access_level.to_s * 4 }

    specify <<-MESSAGE do

        For users with a data access level of #{access_level}, traits having a
        data access level having a lower number shouldn't appear in the traits
        list unless they themselves created it

        MESSAGE

      get "/api/beta/traits.xml?key=#{apikey}&user_id=~#{CGI.escape("^[^#{User.find_by_apikey(apikey).id}]$")}"

      # make sure we got data back:
      expect(response.body).to match(%r{<data>})

      expect(response.body).to_not match(%r{<access-level type="integer">[1-#{access_level - 1}]</access-level>})

    end

    # TO-DO: Also test JSON format


    # Iterate through traits this user shouldn't see and make sure they can't:
    Trait.where("access_level < ?", access_level).each do |t|

      specify <<-MESSAGE do

        Users with a data access level of #{access_level} shouldn't be able to
        view traits having data access level #{t.access_level} unless they
        themselves created it
        MESSAGE

        get "/api/beta/traits/#{t.id}?key=#{apikey}"

        if User.find_by_apikey(apikey).id == t.user_id
          expect(response.body).to include('"trait"')
        else
          expect(response.body).not_to include('"trait"')
        end

      end

      # To-Do: Also test XML format

    end

    # TO-DO: Also test yields index and show actions

  end

  (2..4).each do |access_level|
    include_examples "testing access levels", access_level
  end

end
