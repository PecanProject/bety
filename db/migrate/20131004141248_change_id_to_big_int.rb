class ChangeIdToBigInt < ActiveRecord::Migration
    # convert id of all tables to bigint
    change_column :citations, :id, :integer, :limit => 8
    change_column :counties, :id, :integer, :limit => 8
    change_column :covariates, :id, :integer, :limit => 8
    change_column :cultivars, :id, :integer, :limit => 8
    change_column :dbfiles, :id, :integer, :limit => 8
    change_column :ensembles, :id, :integer, :limit => 8
    change_column :entities, :id, :integer, :limit => 8
    change_column :formats, :id, :integer, :limit => 8
    change_column :formats_variables, :id, :integer, :limit => 8
    change_column :inputs, :id, :integer, :limit => 8
    change_column :likelihoods, :id, :integer, :limit => 8
    change_column :location_yields, :id, :integer, :limit => 8
    change_column :machines, :id, :integer, :limit => 8
    change_column :managements, :id, :integer, :limit => 8
    change_column :methods, :id, :integer, :limit => 8
    change_column :mimetypes, :id, :integer, :limit => 8
    change_column :models, :id, :integer, :limit => 8
    change_column :pfts, :id, :integer, :limit => 8
    change_column :posteriors, :id, :integer, :limit => 8
    change_column :priors, :id, :integer, :limit => 8
    change_column :runs, :id, :integer, :limit => 8
    change_column :sessions, :id, :integer, :limit => 8
    change_column :sites, :id, :integer, :limit => 8
    change_column :species, :id, :integer, :limit => 8
    change_column :traits, :id, :integer, :limit => 8
    change_column :treatments, :id, :integer, :limit => 8
    change_column :users, :id, :integer, :limit => 8
    change_column :variables, :id, :integer, :limit => 8
    change_column :workflows, :id, :integer, :limit => 8
    change_column :yields, :id, :integer, :limit => 8

    # convert all foreign keys to bigint
    change_column :citations, :user_id, :integer, :limit => 8
    change_column :citations_sites, :citation_id, :integer, :limit => 8
    change_column :citations_sites, :site_id, :integer, :limit => 8
    change_column :citations_treatments, :citation_id, :integer, :limit => 8
    change_column :citations_treatments, :treatment_id, :integer, :limit => 8
    change_column :covariates, :trait_id, :integer, :limit => 8
    change_column :covariates, :variable_id, :integer, :limit => 8
    change_column :cultivars, :specie_id, :integer, :limit => 8
    change_column :cultivars, :previous_id, :integer, :limit => 8
    change_column :dbfiles, :created_user_id, :integer, :limit => 8
    change_column :dbfiles, :updated_user_id, :integer, :limit => 8
    change_column :dbfiles, :machine_id, :integer, :limit => 8
    change_column :dbfiles, :container_id, :integer, :limit => 8
    change_column :ensembles, :workflow_id, :integer, :limit => 8
    change_column :entities, :parent_id, :integer, :limit => 8
    change_column :formats_variables, :format_id, :integer, :limit => 8
    change_column :formats_variables, :variable_id, :integer, :limit => 8
    change_column :inputs, :site_id, :integer, :limit => 8
    change_column :inputs, :parent_id, :integer, :limit => 8
    change_column :inputs, :user_id, :integer, :limit => 8
    change_column :inputs, :format_id, :integer, :limit => 8
    change_column :inputs, :file_id, :integer, :limit => 8
    change_column :inputs_runs, :input_id, :integer, :limit => 8
    change_column :inputs_runs, :run_id, :integer, :limit => 8
    change_column :inputs_variables, :input_id, :integer, :limit => 8
    change_column :inputs_variables, :variable_id, :integer, :limit => 8
    change_column :likelihoods, :run_id, :integer, :limit => 8
    change_column :likelihoods, :variable_id, :integer, :limit => 8
    change_column :likelihoods, :input_id, :integer, :limit => 8
    change_column :location_yields, :county_id, :integer, :limit => 8
    change_column :managements, :citation_id, :integer, :limit => 8
    change_column :managements, :user_id, :integer, :limit => 8
    change_column :managements_treatments, :treatment_id, :integer, :limit => 8
    change_column :managements_treatments, :management_id, :integer, :limit => 8
    change_column :methods, :citation_id, :integer, :limit => 8
    change_column :models, :parent_id, :integer, :limit => 8
    change_column :pfts_priors, :pft_id, :integer, :limit => 8
    change_column :pfts_priors, :prior_id, :integer, :limit => 8
    change_column :pfts_species, :pft_id, :integer, :limit => 8
    change_column :pfts_species, :specie_id, :integer, :limit => 8
    change_column :posteriors, :pft_id, :integer, :limit => 8
    change_column :posteriors, :format_id, :integer, :limit => 8
    change_column :posteriors_runs, :posterior_id, :integer, :limit => 8
    change_column :posteriors_runs, :run_id, :integer, :limit => 8
    change_column :priors, :citation_id, :integer, :limit => 8
    change_column :priors, :variable_id, :integer, :limit => 8
    change_column :runs, :model_id, :integer, :limit => 8
    change_column :runs, :site_id, :integer, :limit => 8
    change_column :runs, :ensemble_id, :integer, :limit => 8
    change_column :sessions, :session_id, :integer, :limit => 8
    change_column :sites, :user_id, :integer, :limit => 8
    change_column :traits, :site_id, :integer, :limit => 8
    change_column :traits, :specie_id, :integer, :limit => 8
    change_column :traits, :citation_id, :integer, :limit => 8
    change_column :traits, :cultivar_id, :integer, :limit => 8
    change_column :traits, :treatment_id, :integer, :limit => 8
    change_column :traits, :variable_id, :integer, :limit => 8
    change_column :traits, :user_id, :integer, :limit => 8
    change_column :traits, :entity_id, :integer, :limit => 8
    change_column :traits, :method_id, :integer, :limit => 8
    change_column :treatments, :user_id, :integer, :limit => 8
    change_column :workflows, :site_id, :integer, :limit => 8
    change_column :workflows, :model_id, :integer, :limit => 8
    change_column :yields, :citation_id, :integer, :limit => 8
    change_column :yields, :site_id, :integer, :limit => 8
    change_column :yields, :specie_id, :integer, :limit => 8
    change_column :yields, :treatment_id, :integer, :limit => 8
    change_column :yields, :cultivar_id, :integer, :limit => 8
    change_column :yields, :user_id, :integer, :limit => 8
    change_column :yields, :method_id, :integer, :limit => 8
  def self.up
  end

  def self.down
    # convert id of all tables to integer
    change_column :citations, :id, :integer
    change_column :counties, :id, :integer
    change_column :covariates, :id, :integer
    change_column :cultivars, :id, :integer
    change_column :dbfiles, :id, :integer
    change_column :ensembles, :id, :integer
    change_column :entities, :id, :integer
    change_column :formats, :id, :integer
    change_column :formats_variables, :id, :integer
    change_column :inputs, :id, :integer
    change_column :likelihoods, :id, :integer
    change_column :location_yields, :id, :integer
    change_column :machines, :id, :integer
    change_column :managements, :id, :integer
    change_column :methods, :id, :integer
    change_column :mimetypes, :id, :integer
    change_column :models, :id, :integer
    change_column :pfts, :id, :integer
    change_column :posteriors, :id, :integer
    change_column :priors, :id, :integer
    change_column :runs, :id, :integer
    change_column :sessions, :id, :integer
    change_column :sites, :id, :integer
    change_column :species, :id, :integer
    change_column :traits, :id, :integer
    change_column :treatments, :id, :integer
    change_column :users, :id, :integer
    change_column :variables, :id, :integer
    change_column :workflows, :id, :integer
    change_column :yields, :id, :integer

    # convert all foreign keys to integer
    change_column :citations, :user_id, :integer
    change_column :citations_sites, :citation_id, :integer
    change_column :citations_sites, :site_id, :integer
    change_column :citations_treatments, :citation_id, :integer
    change_column :citations_treatments, :treatment_id, :integer
    change_column :covariates, :trait_id, :integer
    change_column :covariates, :variable_id, :integer
    change_column :cultivars, :specie_id, :integer
    change_column :cultivars, :previous_id, :integer
    change_column :dbfiles, :created_user_id, :integer
    change_column :dbfiles, :updated_user_id, :integer
    change_column :dbfiles, :machine_id, :integer
    change_column :dbfiles, :container_id, :integer
    change_column :ensembles, :workflow_id, :integer
    change_column :entities, :parent_id, :integer
    change_column :formats_variables, :format_id, :integer
    change_column :formats_variables, :variable_id, :integer
    change_column :inputs, :site_id, :integer
    change_column :inputs, :parent_id, :integer
    change_column :inputs, :user_id, :integer
    change_column :inputs, :format_id, :integer
    change_column :inputs, :file_id, :integer
    change_column :inputs_runs, :input_id, :integer
    change_column :inputs_runs, :run_id, :integer
    change_column :inputs_variables, :input_id, :integer
    change_column :inputs_variables, :variable_id, :integer
    change_column :likelihoods, :run_id, :integer
    change_column :likelihoods, :variable_id, :integer
    change_column :likelihoods, :input_id, :integer
    change_column :location_yields, :county_id, :integer
    change_column :managements, :citation_id, :integer
    change_column :managements, :user_id, :integer
    change_column :managements_treatments, :treatment_id, :integer
    change_column :managements_treatments, :management_id, :integer
    change_column :methods, :citation_id, :integer
    change_column :models, :parent_id, :integer
    change_column :pfts_priors, :pft_id, :integer
    change_column :pfts_priors, :prior_id, :integer
    change_column :pfts_species, :pft_id, :integer
    change_column :pfts_species, :specie_id, :integer
    change_column :posteriors, :pft_id, :integer
    change_column :posteriors, :format_id, :integer
    change_column :posteriors_runs, :posterior_id, :integer
    change_column :posteriors_runs, :run_id, :integer
    change_column :priors, :citation_id, :integer
    change_column :priors, :variable_id, :integer
    change_column :runs, :model_id, :integer
    change_column :runs, :site_id, :integer
    change_column :runs, :ensemble_id, :integer
    change_column :sessions, :session_id, :integer
    change_column :sites, :user_id, :integer
    change_column :traits, :site_id, :integer
    change_column :traits, :specie_id, :integer
    change_column :traits, :citation_id, :integer
    change_column :traits, :cultivar_id, :integer
    change_column :traits, :treatment_id, :integer
    change_column :traits, :variable_id, :integer
    change_column :traits, :user_id, :integer
    change_column :traits, :entity_id, :integer
    change_column :traits, :method_id, :integer
    change_column :treatments, :user_id, :integer
    change_column :workflows, :site_id, :integer
    change_column :workflows, :model_id, :integer
    change_column :yields, :citation_id, :integer
    change_column :yields, :site_id, :integer
    change_column :yields, :specie_id, :integer
    change_column :yields, :treatment_id, :integer
    change_column :yields, :cultivar_id, :integer
    change_column :yields, :user_id, :integer
    change_column :yields, :method_id, :integer
  end
end
