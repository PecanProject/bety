# If set, this variable will login the system automatically as this user.
# This is primarily intended for use with the VM's
#BETY_USER=1


# workaround for rspec to silence regex issues: 
# https://github.com/jnicklas/capybara/issues/87
module Rack
  module Utils
    def escape(s)
      CGI.escape(s.to_s)
    end
    def unescape(s)
      CGI.unescape(s)
    end
  end
end

