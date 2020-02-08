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
require 'active_support'
require 'active_support/core_ext'

require 'tmpdir'

require './wrappers/ruby_geocoder/ruby_geocoder_here'
require './wrappers/ruby_geocoder/ruby_geocoder_opencagedata'
require './wrappers/addok'
require './wrappers/demo'
require './wrappers/ign'

require './lib/cache_manager'
require './lib/point_in_polygon'


module GeocoderWrapper
  ActiveSupport::Cache.lookup_store :redis_store
  CACHE = CacheManager.new(ActiveSupport::Cache::RedisStore.new(host: ENV['REDIS_HOST'] || 'localhost', namespace: 'geocoder', expires_in: 60 * 60 * 24 * 1, raise_errors: true))

  ADDOK_FR = Wrappers::Addok.new(CACHE, "#{ENV['ADDOK_FR_HOST'] || 'http://addok-fr'}:#{ENV['ADDOK_FR_PORT'] || '7878'}", 'France', 'poly/france.kml')
  ADDOK_LU = Wrappers::Addok.new(CACHE, "#{ENV['ADDOK_LU_HOST'] || 'http://addok-lu'}:#{ENV['ADDOK_LU_PORT'] || '7878'}", 'Luxemburg', 'poly/luxemburg.kml', PointInPolygon.new('./poly/luxemburg.sqlite'))
  HERE = Wrappers::RubyGeocoderHere.new(CACHE)
  DEMO = Wrappers::Demo.new(CACHE)
  IGN = Wrappers::Ign.new('hxexfaqsph8w23yaxap442ru', CACHE, 'poly/france.kml')

  PARAMS_LIMIT = { locations: 1000 }.freeze
  QUOTAS = [{ daily: 100000, monthly: 1000000 }] # Only taken into account if REDIS_COUNT
  REDIS_COUNT = ENV['REDIS_COUNT_HOST'] && Redis.new(host: ENV['REDIS_COUNT_HOST'])

  @@c = {
    product_title: 'Geocoder API',
    product_contact_email: 'tech@mapotempo.com',
    product_contact_url: 'https://github.com/Mapotempo/geocoder-api',
    access_by_api_key: {
      file: './config/access.rb'
    },
    profiles: {
      standard: {
        geocoders: {
          fra: ADDOK_FR,
          lux: ADDOK_LU,
        },
        geocoder_fallback: DEMO,
        params_limit: PARAMS_LIMIT,
        quotas: QUOTAS, # Only taken into account if REDIS_COUNT
        map: {
          url: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
          options: { zoom: 18, attribution: 'Map data &copy; <a href="https://openstreetmap.org">OpenStreetMap</a> contributors' }
        }
      }
    },
    ruby_geocode: {
      # Set the appropriate authentication if required
      here: ['APP_ID', 'APP_CODE'],
      opencagedata: 'API_KEY'
    },
    redis_count: REDIS_COUNT,
  }
end
