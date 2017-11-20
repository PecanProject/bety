object @row => (@row.class.name == "Specie" ? :species : @row) # correct the object name when viewing a species

if !root_object.nil?

  # Show all columns for this model
  attributes *root_object.class.column_names.map(&:to_sym)


  # Now show information for associations
  children = root_object.class.reflect_on_all_associations(:belongs_to)

  multiple_associations = root_object.class.reflect_on_all_associations(:has_many)

  # List of join tables that don't add any useful information
  excluded_join_tables = [:citation_sites, # excludes citations_sites from both citation and site display
                          :citation_treatments, # excludes citations_treatments from citation display
                          :citations_treatments, # excludes citations_treatments from treatment display
                          :managements_treatments, # excludes managements_treatments from both management and treatment display
                          :posteriors_ensembles, # this association is not working
                          :pfts_priors, # excludes pfts_priors from both pfts and priors display
                          :pfts_species, # excludes pfts_species from both pfts and species display
                          :sitegroups_sites # excludes sitegroups_sites from sites display
                         ]

  # Don't display join table information if no useful information is to be had
  multiple_associations.reject! { |assoc| excluded_join_tables.include?(assoc.name) }

  case @associations_mode
  when :count
    (multiple_associations).each do |assoc|
      node "number of associated #{assoc.name.to_s}" do
        begin
          root_object.send(assoc.name).size
        rescue => e
          Rails.logger.debug("Exception: #{e.message}")
          Rails.logger.debug("Couldn't send #{assoc.name.inspect} to #{root_object.inspect}")
        end
      end
    end
  when :ids
    (multiple_associations).each do |assoc|
      node "associated #{assoc.name.to_s.singularize} ids" do
        begin
          root_object.send(assoc.name).map(&:id)
        rescue => e
          Rails.logger.debug("Exception: #{e.message}")
          Rails.logger.debug("Couldn't send #{assoc.name.inspect} to #{root_object.inspect}")
        end
      end
    end
  when :full_info
    (children + multiple_associations).each do |assoc|
      next if assoc.klass == User
      child assoc.name do
        attributes *assoc.klass.column_names.map(&:to_sym)
      end
    end
  end


  # Show the "show" URL for this object
  node(:view_url) do |ob|
    if !ob.instance_of?(TraitsAndYieldsView)
      polymorphic_url(ob)
    else
      if ob.result_type =~ /traits/
        trait_url(ob.id)
      elsif ob.result_type =~ /yields/
        yield_url(ob.id)
      end
    end
  end

  # Show the "edit" URL for this object
  node(:edit_url) do |ob|
    if !ob.instance_of?(TraitsAndYieldsView)
      edit_polymorphic_url(ob)
    else
      if ob.result_type =~ /traits/
        edit_trait_url(ob.id)
      elsif ob.result_type =~ /yields/
        edit_yield_url(ob.id)
      end
    end
  end

end
