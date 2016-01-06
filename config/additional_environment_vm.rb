config.action_mailer.smtp_settings = {
  :address => 'localhost',
  :domain => 'localhost',
  :port => 25
}
config.action_mailer.perform_deliveries = true
config.action_mailer.raise_delivery_errors = true
config.action_mailer.default_charset = "utf-8"
config.action_mailer.delivery_method = :smtp

config.default_user=1

# contact information settings (for footer and mailer).  CHANGE THESE TO THE
# SETTINGS APPROPRIATE FOR YOUR BETYdb INSTANCE!
::ADMIN_EMAIL = "betydb@gmail.com"
::ADMIN_PHONE = "(217) 300-0266"
