# Copyright © Mapotempo, 2015
#
# This file is part of Mapotempo.
#
# Mapotempo is free software. You can redistribute it and/or
# modify since you respect the terms of the GNU Affero General
# Public License as published by the Free Software Foundation,
# either version 3 of the License, or (at your option) any later version.
#
# Mapotempo is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
# or FITNESS FOR A PARTICULAR PURPOSE.  See the Licenses for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Mapotempo. If not, see:
# <http://www.gnu.org/licenses/agpl.html>
#
ENV['APP_ENV'] ||= 'development'
Bundler.require
require File.expand_path('../config/environments/' + ENV['APP_ENV'], __FILE__)
Dir[File.dirname(__FILE__) + '/config/initializers/*.rb'].each {|file| require file }
require './geocoder_wrapper'
require './api/root'
require 'rack/cors'
require 'rack/contrib/try_static'
require 'tilt'
require 'rack-server-pages'
require 'action_dispatch'

use Rack::ServerPages do |config|
  config.view_path = 'public'
end

run Rack::ServerPages::NotFound

use Rack::Cors do
  allow do
    origins '*'
    resource '*',
      headers: :any,
      methods: :any,
      expose: ['Cache-Control', 'Content-Encoding', 'Content-Type'],
      max_age: 1728000,
      credentials: false
  end
end

#\ -p 8558
run Api::Root

use Rack::Config do |env|
  env['api.tilt.root'] = File.expand_path('public')
end

use ActionDispatch::RemoteIp
