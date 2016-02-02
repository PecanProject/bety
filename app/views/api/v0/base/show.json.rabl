object @row

# Show all columns for this model
attributes *root_object.class.column_names.map(&:to_sym)


# Now show information for associations
children = root_object.class.reflect_on_all_associations(:belongs_to)

multiple_associations = root_object.class.reflect_on_all_associations(:has_many)

# List of join tables that don't add any useful information
excluded_join_tables = [:citation_sites, :citation_treatments,
                        :management_treatments, :posteriors_ensembles,
                        :pft_priors, :pft_species]

# Don't display join table information if no useful information is to be had
multiple_associations.reject! { |assoc| excluded_join_tables.include?(assoc.name) }

if locals[:abbreviate_associations]
  (multiple_associations).each do |assoc|
    node ((assoc.name).to_s + "_ids") do
      begin
        root_object.send(assoc.name).map(&:id)
      rescue => e
        Rails.logger.debug("Exception: #{e.message}")
        Rails.logger.debug("Couldn't send #{assoc.name.inspect} to #{root_object.inspect}")
      end
    end
  end
else
  (children + multiple_associations).each do |assoc|
    child assoc.name do
      attributes *assoc.klass.column_names.map(&:to_sym)
    end
  end
end


# Show the edit URL for this object
node(:edit_url) do |ob|
  edit_site_url(ob)
end
