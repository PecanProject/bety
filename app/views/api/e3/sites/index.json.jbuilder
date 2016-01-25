json.sites @sites do |site|
  json.partial! 'site', site: site
end
