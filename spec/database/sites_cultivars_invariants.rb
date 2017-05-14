require 'spec_helper'

RSpec.describe "Site-Cultivar-Species invariants" do

  context "A new trait is being inserted" do

    let(:t) { Trait.new access_level: 4, mean: 3, variable_id: 5 }

    # CASE 1
    
    specify "A trait with access level, mean, and valid varialbe_id is savable" do

      expect(t.save).to be true

    end

    context "cultivar_id is specified" do

      before { t.cultivar_id = 417 }

      context "No site_id is specified" do
        
        specify "When a cultivar_id is specified for a new trait without specifying a site_id or specie_id, the appropriate specie_id will be set." do

          expect(t.save).to be true

          t.reload

          expect(t.specie_id).to eq 18

        end

        specify "When no site_id is specified for a new trait but a cultivar_id is specified for a new trait and a specie_id inconsistent with the cultivar_id is specified, the attempt to save the trait will be blocked." do

          t.specie_id = 2

          expect { t.save }.to raise_error(ActiveRecord::StatementInvalid, /The species id 2 is not consistent with the cultivar id 417./)

        end

        specify "When no site_id is specified for a new trait but a cultivar_id is specified for a new trait and a specie_id consistent with the cultivar_id is specified, saving the new trait should be successful." do

          t.specie_id = 18

          expect( t.save).to be true

        end

      end

      context "A site_id not in the sites_cultivars table is specified" do

        before { t.site_id = 4 }

        specify "When a cultivar_id and a site_id not in the sites_cultivars table are specified for a new trait without specifying a specie_id, the appropriate specie_id will be set." do

          expect(t.save).to be true

          t.reload

          expect(t.specie_id).to eq 18

        end

        specify "When a cultivar_id and a site_id not in the sites_cultivars table are specified and a specie_id inconsistent with the cultivar_id is specified, the attempt to save the trait will be blocked." do

          t.specie_id = 2

          expect { t.save }.to raise_error(ActiveRecord::StatementInvalid, /The species id 2 is not consistent with the cultivar id 417./)

        end

        specify "When a cultivar_id and a site_id not in the sites_cultivars table are specified and a specie_id consistent with the cultivar_id is specified, the attempt to save the trait will be successful." do

          t.specie_id = 18

          expect(t.save).to be true

        end

      end

    end


    # CASES 2 AND 3
    
    context "A site_id in the sites_cultivars table is specified" do

      before { t.site_id = 1 }

      # CASE 2

      context "No cultivar_id is specified" do

        it "sets the correct cultivar_id and specie_id if neither is specified" do

          expect(t.save).to be true

          t.reload

          expect(t.cultivar_id).to eq 100
          expect(t.specie_id).to eq 938

        end

        it "sets the correct cultivar_id and saves the new trait if a specie_id consistent with the site_id is specified but no cultivar_id is specified" do

          t.specie_id = 938

          expect(t.save).to be true

          t.reload

          expect(t.cultivar_id).to eq 100

        end

        it "blocks saving the new trait if a specie_id inconsistent with the site_id is specified" do

          t.specie_id = 2

          expect { t.save }.to raise_error(ActiveRecord::StatementInvalid, /The species id 2 is not consistent with the cultivar id 100./)

        end

      end

      # CASE 3

      context "A cultivar_id consistent with the site_id is specified" do

        before { t.cultivar_id = 100 }

        it "sets the correct specie_id and saves the new trait if the specie_id is not specified" do

          expect(t.save). to be true

          t.reload

          expect(t.specie_id).to eq 938

        end

        it "saves the new trait if a specie_id consistent with the cultivar_id is specified" do

          t.specie_id = 938

          expect(t.save).to be true

        end

        it "blocks saving the new trait if a specie_id inconsistent with the cultivar_id is specified" do

          t.specie_id = 2

          expect { t.save }.to raise_error(ActiveRecord::StatementInvalid, /The species id 2 is not consistent with the cultivar id 100./)

        end
        
      end

      specify "A cultivar_id inconsistent with the site_id is specified" do

        t.cultivar_id = 417

        expect { t.save }.to raise_error(ActiveRecord::StatementInvalid, /The value of cultivar_id \(417\) is not consistent with the value 100 specified for site_id 1./)

      end
      
    end
    
  end


  context "A trait is being updated" do

  end

end
