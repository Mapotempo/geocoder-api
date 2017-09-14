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
require 'tmpdir'

require './wrappers/addok'
require './wrappers/ruby_geocoder_here'
require './wrappers/ruby_geocoder_opencagedata'
require './wrappers/demo'

require './lib/cache_manager'


module AddokWrapper
  ActiveSupport::Cache.lookup_store :redis_store
  CACHE = CacheManager.new(ActiveSupport::Cache::RedisStore.new(host: ENV['REDIS_HOST'] || 'localhost', namespace: 'router', expires_in: 60*60*24*1, raise_errors: true))

  ADDOK_FRA = Wrappers::Addok.new(CACHE, 'http://api-adresse.data.gouv.fr', 'France', 'poly/france.kml')
  HERE = Wrappers::RubyGeocoderHere.new(CACHE)
  DEMO = Wrappers::Demo.new(CACHE)

  @@c = {
    product_title: 'Addok Wrapper geocoding API',
    product_contact_email: 'tech@mapotempo.com',
    product_contact_url: 'https://github.com/Mapotempo/addok-wrapper',
    profiles: [{
      api_keys: ['demo'],
      geocoders: {
        fra: ADDOK_FRA,
      },
      geocoder_fallback: DEMO
    }],
    ruby_geocode: {
      # Set the appropriate authentication if required
      here: ['APP_ID', 'APP_CODE'],
      opencagedata: 'API_KEY'
    }
  }

  @@c[:api_keys] = Hash[@@c[:profiles].collect{ |profile|
    profile[:api_keys].collect{ |api_key|
      [api_key, profile]
    }
  }.flatten(1)]
end
