# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w(
  bulk_upload.css
  schemaSpy.css

  lazy/login.js
  lazy/map_search.js
  lazy/feedback.js
  lazy/autocomplete.js
  lazy/bulk_upload.js

  mylibs/maps.js
 )

Rails.application.config.assets.paths <<
  Rails.root.join("app", "assets", "stylesheets", "jquery-ui-1.10.4.custom",
                  "css", "ui-lightness").to_s
