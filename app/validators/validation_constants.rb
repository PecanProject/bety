module ValidationConstants

  XALPHAS = %q{([-\w$@.&+!*"'(),]|%[0-9a-f]{2})+} #"
  IALPHA = '[a-z]' + XALPHAS
  HOSTNAME = IALPHA + '(\.' + IALPHA + ')*'
  HOSTNUMBER = '\d+\.\d+\.\d+\.\d+'
  HOST = '(' + HOSTNAME + '|' + HOSTNUMBER + ')'
  SCHEME = '(https?|ftp)'
  OPTIONAL_PORT = '(:\d+)?'
  PATH = '(/' + XALPHAS + ')*'
  OPTIONAL_QUERY_STRING = '(\?' + XALPHAS + ')?'

  URL = SCHEME + '://' + HOST + OPTIONAL_PORT + PATH + OPTIONAL_QUERY_STRING;

  EMAIL = format('%s@%s', XALPHAS, HOSTNAME)

end
