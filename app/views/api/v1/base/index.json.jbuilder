json.data @row_set.each do |row|

  view_url = if !row.instance_of?(TraitsAndYieldsView)
    polymorphic_url(row)
  else
    if row.result_type =~ /traits/
      "#{request.base_url}/traits/#{row.id}"
    elsif row.result_type =~ /yields/
      "#{request.base_url}/yields/#{row.id}"
    end
  end

  edit_url = if !row.instance_of?(TraitsAndYieldsView)
    edit_polymorphic_url(row)
  else
    if row.result_type =~ /traits/
      "#{request.base_url}/traits/#{row.id}/edit"
    elsif row.result_type =~ /yields/
      "#{request.base_url}/yields/#{row.id}/edit"
    end
  end

  children = row.class.reflect_on_all_associations(:belongs_to)

  multiple_associations = row.class.reflect_on_all_associations(:has_many)

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

  json.traits_and_yields_view do
    json.(row, *row.class.column_names.map(&:to_sym))
    json.view_url view_url
    json.edit_url edit_url

    case @associations_mode
    when :count
      (multiple_associations).each do |assoc|
        json.set! "number of associated #{assoc.name.to_s}" do
          begin
            row.send(assoc.name).size
          rescue => e
            Rails.logger.debug("Exception: #{e.message}")
            Rails.logger.debug("Couldn't send #{assoc.name.inspect} to #{row.inspect}")
          end
        end
      end
    when :ids
      (multiple_associations).each do |assoc|
        json.set! "associated #{assoc.name.to_s.singularize} ids" do
          begin
            row.send(assoc.name).map(&:id)
          rescue => e
            Rails.logger.debug("Exception: #{e.message}")
            Rails.logger.debug("Couldn't send #{assoc.name.inspect} to #{row.inspect}")
          end
        end
      end
    when :full_info
      (children + multiple_associations).each do |assoc|
        next if assoc.klass == User
        json.set! assoc.name do
          josn.(attributes *assoc.klass.column_names.map(&:to_sym))
        end
      end
    end

  end
end
