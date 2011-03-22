#\ -w -p 3011
require "user_barcode"
disable :run, :reload

run Sinatra::Application
