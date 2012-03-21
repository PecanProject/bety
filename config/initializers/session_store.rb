# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
#ActionController::Base.session = {
#  :key         => '_ebi_session',
#  :secret      => '230c6eea97c8c1dfc10f2eb57284a82e7e493677f4933ff159b1fe14c05e74b9550ee2170f50baa025c5b5e72f397edaa94e5a718824ccbee5c5a25a6f34cc35'
#}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
ActionController::Base.session_store = :active_record_store
