require 'spec_helper'

RSpec.describe "Site-Cultivar-Species invariants" do

  let(:t) { Trait.new access_level: 4, mean: 3, variable_id: 5 }

  specify "A trait with access level, mean, and valid varialbe_id is savable" do

    expect(t.save).to be true

  end

  specify "When a cultivar_id is specified for a new trait without specifying a site_id or specie_id, the appropriate specie_id will be set." do

    t.cultivar_id = 417

    expect(t.save).to be true

    t.reload

    expect(t.specie_id).to eq 18

   end


  specify "When a cultivar_id and a site_id not in the sites_cultivars table are specified for a new trait without specifying a specie_id, the appropriate specie_id will be set." do

    t.cultivar_id = 417
    t.site_id = 1

    expect(t.save).to be true

    t.reload

    expect(t.specie_id).to eq 18

   end



  specify "When no site_id is specified for a new trait but a cultivar_id is specified for a new trait and a specie_id inconsistent with the cultivar_id is specified, the attempt to save the trait will be blocked." do

    t.cultivar_id = 417

    t.specie_id = 2

    expect { t.save }.to raise_error(ActiveRecord::StatementInvalid, /The species id 2 is not consistent with the cultivar id 417./)

   end

end
