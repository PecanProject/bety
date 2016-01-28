require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
if defined?(Bundler)
  # If you precompile assets before deploying to production, use this line
  Bundler.require *Rails.groups(:assets => %w(development test))
  # If you want your assets lazily compiled in production, use this line
  # Bundler.require(:default, :assets, Rails.env)
end

CONFIG = YAML.load(File.read(File.expand_path('../defaults.yml', __FILE__)))
if File.exists?(File.expand_path('../application.yml', __FILE__))
  customizations = YAML.load(File.read(File.expand_path('../application.yml', __FILE__)))
  CONFIG.update customizations
  CONFIG.merge! CONFIG.fetch(Rails.env, {})
end
CONFIG.symbolize_keys!

module BetyRails3
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    # config.autoload_paths += %W(#{config.root}/extras)

    # RAILS3 - Added to get RESTful authentication working
    # http://stackoverflow.com/questions/7547281/rails-3-restful-authentication-uninitialized-constant-applicationcontrollera
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

    # Set this to avoid a Rails 3.2+ deprecation warning:
    I18n.enforce_available_locales = true

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password, :password_authentication]

    # Don't bother making schema.rb any more:
    config.active_record.schema_format = :sql

    # Until we enable the assets pipeline, ensure the old behavior of javascript_include_tag(:all) with this:
    config.action_view.javascript_expansions[:defaults] = ['prototype', 'effects']
    # Enable the asset pipeline
    # config.assets.enabled = true

    # Version of your assets, change this if you want to expire all your assets
    # config.assets.version = '1.0'
  end
end
