json.site do
  json.site_name @site.sitename
  json.coordinates @site.geometry
  json.added_by do |json|
    json.(@site.user, :name) if @site.user
  end
  json.associated_citations @site.citations do |citation|
    #json.partial! 'citation', citation: citation
    json.citation do
      json.(citation, :year)
    end
  end
end
