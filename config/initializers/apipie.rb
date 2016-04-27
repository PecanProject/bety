Apipie.configure do |config|
  config.app_name                = "BETYdb"
  config.default_version         = "beta"
  config.api_base_url            = ""
  config.doc_base_url            = "/api/docs"
  # where is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/beta/*.rb"


end
