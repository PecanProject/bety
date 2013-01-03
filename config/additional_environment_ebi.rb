config.action_mailer.delivery_method = :smtp
config.action_mailer.smtp_settings = {
  :address => 'express-smtp.cites.uiuc.edu',
  :domain => 'igb.uiuc.edu',
  :port => 25
}
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true
config.action_mailer.default_charset = "utf-8"

