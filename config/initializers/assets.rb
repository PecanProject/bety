# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path
# Rails.application.config.assets.paths << Emoji.images_path

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in app/assets folder are already added.
Rails.application.config.assets.precompile += %w(
  bulk_upload.css

  lazy/login.js
  lazy/map_search.js
  lazy/feedback.js
  lazy/autocomplete.js
  lazy/bulk_upload.js

  lazy/jquery-1.11.0
  libs/jquery-ui-1.10.4.custom/js/jquery-ui-1.10.4.custom
  libs/jquery-migrate-1.2.1

  lazy/jquery-1.7.2
  lazy/jquery-ui-1.10.4.min

  libs/jquery-1.6.2.min

  cache/all

  prototype
  effects
  bootstrap
  controls
  dragdrop
  min
  plugins
  rails
  script
  window

  libs/respond.min.js
  libs/modernizr-2.0.6.min

  lazy/simple_search
  lazy/application
 )

Rails.application.config.assets.paths <<
  Rails.root.join("app", "assets", "stylesheets", "jquery-ui-1.10.4.custom",
                  "css", "ui-lightness").to_s
