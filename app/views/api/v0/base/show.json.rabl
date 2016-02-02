object @row

# Show all columns for this model
attributes *root_object.class.column_names.map(&:to_sym)


# Now show information for associations
children = root_object.class.reflect_on_all_associations(:belongs_to)


many_to_many_associations = root_object.class.reflect_on_all_associations(:has_many)

many_to_many_associations.select! do |assoc|
  begin
    assoc.klass.reflect_on_all_associations(:has_many).map(&:klass).try(:include?, root_object.class)
  rescue => e
    nil
  end
end


(children + many_to_many_associations).each do |assoc|
  child assoc.name do
    if locals[:abbreviate_associations]
      attributes :id
    else
      attributes *assoc.klass.column_names.map(&:to_sym)
    end
  end
end


# Show the edit URL for this object
node(:edit_url) do |ob|
  edit_site_url(ob)
end
