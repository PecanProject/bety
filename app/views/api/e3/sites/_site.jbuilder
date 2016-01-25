json.site do
  json.site_name site.sitename
  json.coordinates site.geometry
  json.location "#{site.city},#{ site.state.blank? ? "" : " #{site.state},"} #{site.country}"
  json.added_by site.user, :name, :login if site.user
  json.associated_citations site.citations, :author, :year, :title
  json.id site.id
end
