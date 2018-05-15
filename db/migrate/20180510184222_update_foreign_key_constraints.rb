class UpdateForeignKeyConstraints < ActiveRecord::Migration
  def self.up
	execute %q{

/* These constraints are being updated to use the "ON UPDATE CASCADE" clause so
that rows having misallocated id numbers can be updated to use ids in the
correct range without violating foreign key constraints.  A few constraints are
new. */

ALTER TABLE "posteriors_ensembles" DROP CONSTRAINT "fk_posteriors_ensembles_ensembles_1";
ALTER TABLE "posteriors_ensembles" ADD CONSTRAINT "fk_posteriors_ensembles_ensembles_1" FOREIGN KEY ("ensemble_id") REFERENCES "ensembles" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "runs" DROP CONSTRAINT "fk_runs_ensembles_1";
ALTER TABLE "runs" ADD CONSTRAINT "fk_runs_ensembles_1" FOREIGN KEY ("ensemble_id") REFERENCES "ensembles" ("id") ON UPDATE CASCADE;

ALTER TABLE "inputs" DROP CONSTRAINT "fk_inputs_inputs_1";
ALTER TABLE "inputs" ADD CONSTRAINT "fk_inputs_inputs_1" FOREIGN KEY ("parent_id") REFERENCES "inputs" ("id") ON UPDATE CASCADE         not valid;

ALTER TABLE "inputs_runs" DROP CONSTRAINT "fk_inputs_runs_inputs_1";
ALTER TABLE "inputs_runs" ADD CONSTRAINT "fk_inputs_runs_inputs_1" FOREIGN KEY ("input_id") REFERENCES "inputs" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "likelihoods" DROP CONSTRAINT "fk_likelihoods_inputs_1";
ALTER TABLE "likelihoods" ADD CONSTRAINT "fk_likelihoods_inputs_1" FOREIGN KEY ("input_id") REFERENCES "inputs" ("id") ON UPDATE CASCADE;

/* New foreign-key constraint. */
ALTER TABLE "formats" ADD CONSTRAINT "fk_formats_mimetypes" FOREIGN KEY ("mimetype_id") REFERENCES "mimetypes" ("id") ON UPDATE CASCADE NOT VALID;

ALTER TABLE current_posteriors DROP CONSTRAINT fk_current_posteriors_pfts_1;
ALTER TABLE current_posteriors ADD CONSTRAINT fk_current_posteriors_pfts_1 FOREIGN KEY (pft_id) REFERENCES pfts(id) ON UPDATE CASCADE;

ALTER TABLE "pfts" DROP CONSTRAINT "fk_pfts_pfts_1";
ALTER TABLE "pfts" ADD CONSTRAINT "fk_pfts_pfts_1" FOREIGN KEY ("parent_id") REFERENCES "pfts" ("id") ON UPDATE CASCADE;

/* Only on terraref.ncsa.illinois.edu. */
ALTER TABLE "pfts_priors" DROP CONSTRAINT IF EXISTS "fk_pfts_priors_pfts_1";
ALTER TABLE "pfts_priors" ADD CONSTRAINT "fk_pfts_priors_pfts_1" FOREIGN KEY ("pft_id") REFERENCES "pfts" ("id") ON DELETE CASCADE ON UPDATE CASCADE NOT VALID;

ALTER TABLE "posteriors" DROP CONSTRAINT "fk_posteriors_pfts_1";
ALTER TABLE "posteriors" ADD CONSTRAINT "fk_posteriors_pfts_1" FOREIGN KEY ("pft_id") REFERENCES "pfts" ("id") ON UPDATE CASCADE;

ALTER TABLE "posterior_samples" DROP CONSTRAINT "fk_posterior_samples_pfts_1";
ALTER TABLE "posterior_samples" ADD CONSTRAINT "fk_posterior_samples_pfts_1" FOREIGN KEY ("pft_id") REFERENCES "pfts" ("id") ON UPDATE CASCADE;

ALTER TABLE "posterior_samples" DROP CONSTRAINT "fk_posterior_samples_posteriors_1";
ALTER TABLE "posterior_samples" ADD CONSTRAINT "fk_posterior_samples_posteriors_1" FOREIGN KEY ("posterior_id") REFERENCES "posteriors" ("id") ON UPDATE CASCADE;

ALTER TABLE "posteriors_ensembles" DROP CONSTRAINT "fk_posteriors_ensembles_posteriors_1";
ALTER TABLE "posteriors_ensembles" ADD CONSTRAINT "fk_posteriors_ensembles_posteriors_1" FOREIGN KEY ("posterior_id") REFERENCES "posteriors" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "inputs_runs" DROP CONSTRAINT "fk_inputs_runs_runs_1";
ALTER TABLE "inputs_runs" ADD CONSTRAINT "fk_inputs_runs_runs_1" FOREIGN KEY ("run_id") REFERENCES "runs" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "likelihoods" DROP CONSTRAINT "fk_likelihoods_runs_1";
ALTER TABLE "likelihoods" ADD CONSTRAINT "fk_likelihoods_runs_1" FOREIGN KEY ("run_id") REFERENCES "runs" ("id") ON UPDATE CASCADE;

ALTER TABLE "citations_sites" DROP CONSTRAINT "fk_citations_sites_sites_1";
ALTER TABLE "citations_sites" ADD CONSTRAINT "fk_citations_sites_sites_1" FOREIGN KEY ("site_id") REFERENCES "sites" ("id") ON DELETE RESTRICT ON UPDATE CASCADE      not valid;

ALTER TABLE "inputs" DROP CONSTRAINT "fk_inputs_sites_1";
ALTER TABLE "inputs" ADD CONSTRAINT "fk_inputs_sites_1" FOREIGN KEY ("site_id") REFERENCES "sites" ("id") ON UPDATE CASCADE                    not valid;

ALTER TABLE "runs" DROP CONSTRAINT "fk_runs_sites_1";
ALTER TABLE "runs" ADD CONSTRAINT "fk_runs_sites_1" FOREIGN KEY ("site_id") REFERENCES "sites" ("id") ON UPDATE CASCADE                        not valid;

/* Only on terraref.ncsa.illinois.edu. */
ALTER TABLE "traits" DROP CONSTRAINT IF EXISTS "fk_traits_sites_1";
ALTER TABLE "traits" ADD CONSTRAINT "fk_traits_sites_1" FOREIGN KEY ("site_id") REFERENCES "sites" ("id") ON UPDATE CASCADE NOT VALID;

ALTER TABLE "workflows" DROP CONSTRAINT "fk_workflows_sites_1";
ALTER TABLE "workflows" ADD CONSTRAINT "fk_workflows_sites_1" FOREIGN KEY ("site_id") REFERENCES "sites" ("id") ON UPDATE CASCADE               not valid;

/* Only on terraref.ncsa.illinois.edu. */
ALTER TABLE "yields" DROP CONSTRAINT IF EXISTS "fk_yields_sites_1";
ALTER TABLE "yields" ADD CONSTRAINT "fk_yields_sites_1" FOREIGN KEY ("site_id") REFERENCES "sites" ("id") ON UPDATE CASCADE NOT VALID;

ALTER TABLE "citations_treatments" DROP CONSTRAINT "fk_citations_treatments_treatments_1";
ALTER TABLE "citations_treatments" ADD CONSTRAINT "fk_citations_treatments_treatments_1" FOREIGN KEY ("treatment_id") REFERENCES "treatments" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "managements_treatments" DROP CONSTRAINT "fk_managements_treatments_treatments_1";
ALTER TABLE "managements_treatments" ADD CONSTRAINT "fk_managements_treatments_treatments_1" FOREIGN KEY ("treatment_id") REFERENCES "treatments" ("id") ON DELETE CASCADE ON UPDATE CASCADE;

/* Only on terraref.ncsa.illinois.edu. */
ALTER TABLE "traits" DROP CONSTRAINT IF EXISTS "fk_traits_treatments_1";
ALTER TABLE "traits" ADD CONSTRAINT "fk_traits_treatments_1" FOREIGN KEY ("treatment_id") REFERENCES "treatments" ("id") ON UPDATE CASCADE NOT VALID;

ALTER TABLE "yields" DROP CONSTRAINT "fk_yields_treatments_1";
ALTER TABLE "yields" ADD CONSTRAINT "fk_yields_treatments_1" FOREIGN KEY ("treatment_id") REFERENCES "treatments" ("id") ON UPDATE CASCADE;

ALTER TABLE "ensembles" DROP CONSTRAINT "fk_ensembles_workflows_1";
ALTER TABLE "ensembles" ADD CONSTRAINT "fk_ensembles_workflows_1" FOREIGN KEY ("workflow_id") REFERENCES "workflows" ("id") ON UPDATE CASCADE;

ALTER TABLE "yields" DROP CONSTRAINT "fk_yields_treatments_1";
ALTER TABLE "yields" ADD CONSTRAINT "fk_yields_treatments_1" FOREIGN KEY ("treatment_id") REFERENCES "treatments" ("id") ON UPDATE CASCADE;

ALTER TABLE "ensembles" DROP CONSTRAINT "fk_ensembles_workflows_1";
ALTER TABLE "ensembles" ADD CONSTRAINT "fk_ensembles_workflows_1" FOREIGN KEY ("workflow_id") REFERENCES "workflows" ("id") ON UPDATE CASCADE;


/* Other missing constraints */
ALTER TABLE "benchmarks_ensembles" ADD CONSTRAINT "citation_exists" FOREIGN KEY ("citation_id") REFERENCES "citations" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "benchmarks_ensembles" ADD CONSTRAINT "user_exists" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "benchmarks" ADD CONSTRAINT "user_exists" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "benchmark_sets" ADD CONSTRAINT "user_exists" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "covariates" ADD CONSTRAINT "trait_exists" FOREIGN KEY ("trait_id") REFERENCES "traits" ("id") ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
ALTER TABLE "benchmarks_ensembles_scores" ADD CONSTRAINT "user_exists" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "metrics" ADD CONSTRAINT "citation_exists" FOREIGN KEY ("citation_id") REFERENCES "citations" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "metrics" ADD CONSTRAINT "user_exists" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "reference_runs" ADD CONSTRAINT "user_exists" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "formats" ADD CONSTRAINT "mimetype_exists" FOREIGN KEY ("mimetype_id") REFERENCES "mimetypes" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "pfts_priors" ADD CONSTRAINT "pft_exists" FOREIGN KEY ("pft_id") REFERENCES "pfts" ("id") ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
ALTER TABLE "pfts_priors" ADD CONSTRAINT "prior_exists" FOREIGN KEY ("prior_id") REFERENCES "priors" ("id") ON UPDATE CASCADE ON DELETE CASCADE NOT VALID;
ALTER TABLE "traits" ADD CONSTRAINT "site_exists" FOREIGN KEY ("site_id") REFERENCES "sites" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "traits" ADD CONSTRAINT "species_exists" FOREIGN KEY ("specie_id") REFERENCES "species" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "traits" ADD CONSTRAINT "citation_exists" FOREIGN KEY ("citation_id") REFERENCES "citations" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "traits" ADD CONSTRAINT "cultivar_exists" FOREIGN KEY ("cultivar_id") REFERENCES "cultivars" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "traits" ADD CONSTRAINT "treatment_exists" FOREIGN KEY ("treatment_id") REFERENCES "treatments" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "traits" ADD CONSTRAINT "variable_exists" FOREIGN KEY ("variable_id") REFERENCES "variables" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "traits" ADD CONSTRAINT "user_exists" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "traits" ADD CONSTRAINT "entity_exists" FOREIGN KEY ("entity_id") REFERENCES "entities" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "traits" ADD CONSTRAINT "method_exists" FOREIGN KEY ("method_id") REFERENCES "methods" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "treatments" ADD CONSTRAINT "user_exists" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "yields" ADD CONSTRAINT "site_exists" FOREIGN KEY ("site_id") REFERENCES "sites" ("id") ON UPDATE CASCADE NOT VALID;
ALTER TABLE "yields" ADD CONSTRAINT "entity_exists" FOREIGN KEY ("entity_id") REFERENCES "entities" ("id") ON UPDATE CASCADE NOT VALID;
}

    ['Input', 'Model', 'Posterior'].each do |container_type|
      execute %{
    CREATE OR REPLACE FUNCTION forbid_dangling_#{container_type.downcase}_references() RETURNS TRIGGER AS $$
BEGIN
    IF
        OLD.id = SOME(SELECT container_id FROM dbfiles WHERE container_type = '#{container_type}')
        AND TG_OP = 'DELETE'
    THEN
        RAISE NOTICE 'You can''t remove the row with id % because it is referred to by some dbfile.', OLD.id;
        RETURN NULL;
    ELSIF
        TG_OP = 'UPDATE'
    THEN
        RAISE NOTICE 'About to update container_id in rows of dbfiles table where container_type is #{container_type}.';
        RAISE NOTICE 'For this to work, you should drop the "valid_#{container_type.downcase}_refs" constraint before updating #{container_type.downcase} ids and re-add it after you are done.';
        UPDATE dbfiles SET container_id = NEW.id WHERE container_id = OLD.id AND container_type = '#{container_type}';
        RETURN NEW;
    END IF;

    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS forbid_dangling_#{container_type.downcase}_references ON #{container_type.downcase}s;
CREATE TRIGGER forbid_dangling_#{container_type.downcase}_references
    BEFORE DELETE OR UPDATE OF id ON #{container_type.downcase}s
FOR EACH ROW
    EXECUTE PROCEDURE forbid_dangling_#{container_type.downcase}_references();

}
    end
  end

  def self.down
	execute %q{
ALTER TABLE "posteriors_ensembles" DROP CONSTRAINT "fk_posteriors_ensembles_ensembles_1";
ALTER TABLE "posteriors_ensembles" ADD CONSTRAINT "fk_posteriors_ensembles_ensembles_1" FOREIGN KEY ("ensemble_id") REFERENCES "ensembles" ("id") ON DELETE CASCADE;

ALTER TABLE "runs" DROP CONSTRAINT "fk_runs_ensembles_1";
ALTER TABLE "runs" ADD CONSTRAINT "fk_runs_ensembles_1" FOREIGN KEY ("ensemble_id") REFERENCES "ensembles" ("id");

ALTER TABLE "inputs" DROP CONSTRAINT "fk_inputs_inputs_1";
ALTER TABLE "inputs" ADD CONSTRAINT "fk_inputs_inputs_1" FOREIGN KEY ("parent_id") REFERENCES "inputs" ("id")          not valid;

ALTER TABLE "inputs_runs" DROP CONSTRAINT "fk_inputs_runs_inputs_1";
ALTER TABLE "inputs_runs" ADD CONSTRAINT "fk_inputs_runs_inputs_1" FOREIGN KEY ("input_id") REFERENCES "inputs" ("id") ON DELETE CASCADE;

ALTER TABLE "likelihoods" DROP CONSTRAINT "fk_likelihoods_inputs_1";
ALTER TABLE "likelihoods" ADD CONSTRAINT "fk_likelihoods_inputs_1" FOREIGN KEY ("input_id") REFERENCES "inputs" ("id");

/*[update trigger functions on dbfiles]*/

/* Drop new foreign-key constraint. */
ALTER TABLE "formats" DROP CONSTRAINT "fk_formats_mimetypes";

ALTER TABLE current_posteriors DROP CONSTRAINT fk_current_posteriors_pfts_1;
ALTER TABLE current_posteriors ADD CONSTRAINT fk_current_posteriors_pfts_1 FOREIGN KEY (pft_id) REFERENCES pfts(id);

ALTER TABLE "pfts" DROP CONSTRAINT "fk_pfts_pfts_1";
ALTER TABLE "pfts" ADD CONSTRAINT "fk_pfts_pfts_1" FOREIGN KEY ("parent_id") REFERENCES "pfts" ("id");

/* Only on terraref.ncsa.illinois.edu. */
ALTER TABLE "pfts_priors" DROP CONSTRAINT IF EXISTS "fk_pfts_priors_pfts_1";
/* On terraref.ncsa.illinois.edu, add the constraint back outside of this migration. */

ALTER TABLE "posteriors" DROP CONSTRAINT "fk_posteriors_pfts_1";
ALTER TABLE "posteriors" ADD CONSTRAINT "fk_posteriors_pfts_1" FOREIGN KEY ("pft_id") REFERENCES "pfts" ("id");

ALTER TABLE "posterior_samples" DROP CONSTRAINT "fk_posterior_samples_pfts_1";
ALTER TABLE "posterior_samples" ADD CONSTRAINT "fk_posterior_samples_pfts_1" FOREIGN KEY ("pft_id") REFERENCES "pfts" ("id");

ALTER TABLE "posterior_samples" DROP CONSTRAINT "fk_posterior_samples_posteriors_1";
ALTER TABLE "posterior_samples" ADD CONSTRAINT "fk_posterior_samples_posteriors_1" FOREIGN KEY ("posterior_id") REFERENCES "posteriors" ("id");

ALTER TABLE "posteriors_ensembles" DROP CONSTRAINT "fk_posteriors_ensembles_posteriors_1";
ALTER TABLE "posteriors_ensembles" ADD CONSTRAINT "fk_posteriors_ensembles_posteriors_1" FOREIGN KEY ("posterior_id") REFERENCES "posteriors" ("id") ON DELETE CASCADE;

ALTER TABLE "inputs_runs" DROP CONSTRAINT "fk_inputs_runs_runs_1";
ALTER TABLE "inputs_runs" ADD CONSTRAINT "fk_inputs_runs_runs_1" FOREIGN KEY ("run_id") REFERENCES "runs" ("id") ON DELETE CASCADE;

ALTER TABLE "likelihoods" DROP CONSTRAINT "fk_likelihoods_runs_1";
ALTER TABLE "likelihoods" ADD CONSTRAINT "fk_likelihoods_runs_1" FOREIGN KEY ("run_id") REFERENCES "runs" ("id");

ALTER TABLE "citations_sites" DROP CONSTRAINT "fk_citations_sites_sites_1";
ALTER TABLE "citations_sites" ADD CONSTRAINT "fk_citations_sites_sites_1" FOREIGN KEY ("site_id") REFERENCES "sites" ("id") ON DELETE RESTRICT         not valid;

ALTER TABLE "inputs" DROP CONSTRAINT "fk_inputs_sites_1";
ALTER TABLE "inputs" ADD CONSTRAINT "fk_inputs_sites_1" FOREIGN KEY ("site_id") REFERENCES "sites" ("id") not valid;

ALTER TABLE "runs" DROP CONSTRAINT "fk_runs_sites_1";
ALTER TABLE "runs" ADD CONSTRAINT "fk_runs_sites_1" FOREIGN KEY ("site_id") REFERENCES "sites" ("id") not valid;

/* Only on terraref.ncsa.illinois.edu. */
ALTER TABLE "traits" DROP CONSTRAINT IF EXISTS "fk_traits_sites_1";
/* On terraref.ncsa.illinois.edu, add the constraint back outside of this migration. */

ALTER TABLE "workflows" DROP CONSTRAINT "fk_workflows_sites_1";
ALTER TABLE "workflows" ADD CONSTRAINT "fk_workflows_sites_1" FOREIGN KEY ("site_id") REFERENCES "sites" ("id") not valid;

/* Only on terraref.ncsa.illinois.edu. */
ALTER TABLE "yields" DROP CONSTRAINT IF EXISTS "fk_yields_sites_1";
/* On terraref.ncsa.illinois.edu, add the constraint back outside of this migration. */

ALTER TABLE "citations_treatments" DROP CONSTRAINT "fk_citations_treatments_treatments_1";
ALTER TABLE "citations_treatments" ADD CONSTRAINT "fk_citations_treatments_treatments_1" FOREIGN KEY ("treatment_id") REFERENCES "treatments" ("id") ON DELETE CASCADE;

ALTER TABLE "managements_treatments" DROP CONSTRAINT "fk_managements_treatments_treatments_1";
ALTER TABLE "managements_treatments" ADD CONSTRAINT "fk_managements_treatments_treatments_1" FOREIGN KEY ("treatment_id") REFERENCES "treatments" ("id") ON DELETE CASCADE;

/* Only on terraref.ncsa.illinois.edu. */
ALTER TABLE "traits" DROP CONSTRAINT IF EXISTS "fk_traits_treatments_1";
/* On terraref.ncsa.illinois.edu, add the constraint back outside of this migration. */

ALTER TABLE "yields" DROP CONSTRAINT "fk_yields_treatments_1";
ALTER TABLE "yields" ADD CONSTRAINT "fk_yields_treatments_1" FOREIGN KEY ("treatment_id") REFERENCES "treatments" ("id");

ALTER TABLE "ensembles" DROP CONSTRAINT "fk_ensembles_workflows_1";
ALTER TABLE "ensembles" ADD CONSTRAINT "fk_ensembles_workflows_1" FOREIGN KEY ("workflow_id") REFERENCES "workflows" ("id");

ALTER TABLE "yields" DROP CONSTRAINT "fk_yields_treatments_1";
ALTER TABLE "yields" ADD CONSTRAINT "fk_yields_treatments_1" FOREIGN KEY ("treatment_id") REFERENCES "treatments" ("id");

ALTER TABLE "ensembles" DROP CONSTRAINT "fk_ensembles_workflows_1";
ALTER TABLE "ensembles" ADD CONSTRAINT "fk_ensembles_workflows_1" FOREIGN KEY ("workflow_id") REFERENCES "workflows" ("id");

/* Drop all entirely new constraints. */
ALTER TABLE "benchmarks_ensembles" DROP CONSTRAINT "citation_exists";
ALTER TABLE "benchmarks_ensembles" DROP CONSTRAINT "user_exists";
ALTER TABLE "benchmarks" DROP CONSTRAINT "user_exists";
ALTER TABLE "benchmark_sets" DROP CONSTRAINT "user_exists";
ALTER TABLE "covariates" DROP CONSTRAINT "trait_exists";
ALTER TABLE "benchmarks_ensembles_scores" DROP CONSTRAINT "user_exists";
ALTER TABLE "metrics" DROP CONSTRAINT "citation_exists";
ALTER TABLE "metrics" DROP CONSTRAINT "user_exists";
ALTER TABLE "reference_runs" DROP CONSTRAINT "user_exists";
ALTER TABLE "formats" DROP CONSTRAINT "mimetype_exists";
ALTER TABLE "pfts_priors" DROP CONSTRAINT "pft_exists";
ALTER TABLE "pfts_priors" DROP CONSTRAINT "prior_exists";
ALTER TABLE "traits" DROP CONSTRAINT "site_exists";
ALTER TABLE "traits" DROP CONSTRAINT "species_exists";
ALTER TABLE "traits" DROP CONSTRAINT "citation_exists";
ALTER TABLE "traits" DROP CONSTRAINT "cultivar_exists";
ALTER TABLE "traits" DROP CONSTRAINT "treatment_exists";
ALTER TABLE "traits" DROP CONSTRAINT "variable_exists";
ALTER TABLE "traits" DROP CONSTRAINT "user_exists";
ALTER TABLE "traits" DROP CONSTRAINT "entity_exists";
ALTER TABLE "traits" DROP CONSTRAINT "method_exists";
ALTER TABLE "treatments" DROP CONSTRAINT "user_exists";
ALTER TABLE "yields" DROP CONSTRAINT "site_exists";
ALTER TABLE "yields" DROP CONSTRAINT "entity_exists";


}

    ['Input', 'Model', 'Posterior'].each do |container_type|
      execute %{
    CREATE OR REPLACE FUNCTION forbid_dangling_#{container_type.downcase}_references() RETURNS TRIGGER AS $$
BEGIN
    IF
        OLD.id = SOME(SELECT container_id FROM dbfiles WHERE container_type = '#{container_type}')
        AND (TG_OP IN ('DELETE', 'TRUNCATE') OR NEW.id != OLD.id)
    THEN
        RAISE NOTICE 'You can''t remove or change the id of the row with id % because it is referred to by some dbfile.', OLD.id;
        RETURN NULL;
    END IF;

    IF
        TG_OP = 'DELETE'
    THEN
        RETURN OLD;
    END IF;
    
    RETURN NEW; -- for UPDATEs
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS forbid_dangling_#{container_type.downcase}_references ON #{container_type.downcase}s;
CREATE TRIGGER forbid_dangling_#{container_type.downcase}_references
    BEFORE DELETE OR UPDATE ON #{container_type.downcase}s
FOR EACH ROW
    EXECUTE PROCEDURE forbid_dangling_#{container_type.downcase}_references();
}
    end
    
  end
end
