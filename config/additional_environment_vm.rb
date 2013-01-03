config.action_controller.relative_url_root = '/bety'

config.action_mailer.smtp_settings = {
  :address => 'localhost',
  :domain => 'localhost',
  :port => 25
}
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true
config.action_mailer.default_charset = "utf-8"
config.action_mailer.delivery_method = :smtp
