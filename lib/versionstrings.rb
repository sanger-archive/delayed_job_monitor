begin
  require File.join(APP_ROOT,'lib/deployed_version')
rescue LoadError
  module Deployed
    APP_NAME = File.split(File.expand_path(File.dirname(__FILE__)+"/../")).last.capitalize
    VERSION_ID = 'LOCAL'
    VERSION_STRING = "#{APP_NAME} LOCAL [#{ RAILS_ENV }]"
  end
end
