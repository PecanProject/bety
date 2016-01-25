object @site
attributes :sitename, :geometry


node(:edit_url) do |site|
  edit_site_url(site)
end

child :user do
  attributes :name, :login, :email
  node(:url) do |user|
    user_url(user)
  end
end

child :citations do
  attributes :author
end
