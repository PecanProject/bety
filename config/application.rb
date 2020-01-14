require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module BetyRails5
  class Application < Rails::Application

    # Enable Hash#deep_symbolize_keys method defined in lib/symbolize_helper.rb.
    # We may be able to remove lib/symbolize_helper.rb and use the
    # deep_symbolize_keys method built into Rails 4.02 once we upgrade.
    require 'symbolize_helper'
    using SymbolizeHelper

    # Define top-level Hash constant CONFIG by merging settings in defaults.yml and application.yml.
    ::CONFIG = YAML.load(File.read(File.expand_path('../defaults.yml', __FILE__))).deep_symbolize_keys
    if File.exists?(File.expand_path('../application.yml', __FILE__))
      customizations = YAML.load(File.read(File.expand_path('../application.yml', __FILE__))).deep_symbolize_keys
      ::CONFIG.update customizations
      ::CONFIG.merge! CONFIG.fetch(Rails.env, {})
    end

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # RAILS3 - Added to get RESTful authentication working
    # http://stackoverflow.com/questions/7547281/rails-3-restful-authentication-uninitialized-constant-applicationcontrollera
    # Also added non-standard path app/validators.
    config.autoload_paths << "#{Rails.root}/lib" << "#{Rails.root}/app/validators"

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Central Time (US & Canada)'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    # Enable escaping HTML in JSON.
    config.active_support.escape_html_entities_in_json = true

    # Use SQL instead of Active Record's schema dumper when creating the database.
    # This is necessary if your schema can't be completely dumped by the schema dumper,
    # like if you have constraints or database-specific column types
    config.active_record.schema_format = :sql

    # Enforce whitelist mode for mass assignment.
    # This will create an empty whitelist of attributes available for mass-assignment for all models
    # in your app. As such, your models will need to explicitly whitelist or blacklist accessible
    # parameters by using an attr_accessible or attr_protected declaration.
    # config.active_record.whitelist_attributes = true

    # Until we enable the assets pipeline, ensure the old behavior of javascript_include_tag(:all) with this:
#    config.action_view.javascript_expansions[:defaults] = ['prototype', 'effects']
    # Enable the asset pipeline
    # config.assets.enabled = true
  end
end
