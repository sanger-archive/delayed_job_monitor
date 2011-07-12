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
DELAYED_JOB_HTTP_ERROR= 503
DELAYED_JOB_HTTP_OK = 200

helpers do
  def get_version_string
    require File.join(APP_ROOT,'lib/versionstrings')
    Deployed::VERSION_STRING
  end
  
  def delayed_job_connection(application_name)
    DelayedJob.establish_connection(
      @@database["#{RAILS_ENV}_#{application_name}"]
    )
  end
  
  def generate_default_status_page(application_name, max_pending_jobs, max_failed_jobs, max_delayed_job_age_in_days)
      delayed_job_connection(application_name)

      if (number_of_delayed_jobs > max_pending_jobs || number_of_failed_jobs > max_failed_jobs || number_of_old_delayed_jobs(max_delayed_job_age_in_days) > 0)
        http_status_code =  DELAYED_JOB_HTTP_ERROR 
      else
        http_status_code = DELAYED_JOB_HTTP_OK
      end
      
      render_page(http_status_code, "#{number_of_delayed_jobs} jobs pending")
  end
  
  def generate_warehouse_status_page(application_name, max_delayed_job_age_in_days)
    delayed_job_connection(application_name)

    number_of_old_jobs = number_of_old_delayed_jobs(max_delayed_job_age_in_days)
    
    if number_of_old_jobs > 0
      http_status_code =  DELAYED_JOB_HTTP_ERROR 
    else
      http_status_code = DELAYED_JOB_HTTP_OK
    end
      
    render_page(http_status_code, "#{number_of_delayed_jobs} jobs pending, #{number_of_old_jobs} job older than #{max_delayed_job_age_in_days} day(s)")
  end
  
  def number_of_old_delayed_jobs(max_delayed_job_age_in_days)
    DelayedJob.count(:conditions => ["created_at < SUBDATE(NOW(), INTERVAL #{max_delayed_job_age_in_days} DAY)"])
  end
  
  def number_of_delayed_jobs
    DelayedJob.count
  end
  
  def number_of_failed_jobs
    DelayedJob.count(:conditions => [ 'last_error is not NULL' ])
  end
  
  def render_page(http_status_code, text_to_render)
    status http_status_code
    content_type 'text/plain', :charset => 'utf-8'
    <<-_EOF_
    #{text_to_render}
    _EOF_
  end
  
end

class DelayedJob < ActiveRecord::Base
end

get '/sequencescape' do
  generate_default_status_page('sequencescape', 8, 0, 1)
end

get '/process_tracking' do
  generate_default_status_page('process_tracking', 8, 0, 1)
end

get '/warehouse_two' do
  generate_warehouse_status_page('warehouse_two', 3 )
end

get '/' do
  content_type 'text/plain', :charset => 'utf-8'
  get_version_string
end
