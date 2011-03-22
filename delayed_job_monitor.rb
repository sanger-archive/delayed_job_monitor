require 'rubygems'
require 'bundler'
require "rexml/document"
Bundler.setup
require 'sinatra'
require 'active_record'
require 'lib/barcode'

APP_ROOT = File.dirname(File.expand_path(__FILE__))
RAILS_ENV = (ENV['RAILS_ENV'] ||= 'development')
@@database = YAML::load(File.open( File.join(APP_ROOT,'config/database.yml') ))

helpers do
  def get_version_string
    require File.join(APP_ROOT,'lib/versionstrings')
    Deployed::VERSION_STRING
  end
  
  def generate_page(application_name)
      DelayedJob.establish_connection(
        @@database["#{RAILS_ENV}_#{application_name}"]
      )
      number_of_jobs = DelayedJob.count
      number_of_failed_jobs = DelayedJob.find(:all, :conditions => [ 'last_error is not NULL' ]).count

      status 503 if (number_of_jobs > 8 || number_of_failed_jobs > 0)
      content_type 'text/plain', :charset => 'utf-8'
      <<-_EOF_
#{DelayedJob.count} Delayed jobs pending
    _EOF_
  end
end

class DelayedJob < ActiveRecord::Base
end

get '/sequencescape' do
  generate_page('sequencescape')
end

get '/process_tracking' do
  generate_page('process_tracking')
end

get '/' do
  content_type 'text/plain', :charset => 'utf-8'
  get_version_string
end
