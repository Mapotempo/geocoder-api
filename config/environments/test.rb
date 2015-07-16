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
require './wrappers/addok'
require './wrappers/ruby_geocoder_google'
require './wrappers/ruby_geocoder_here'
require './wrappers/ruby_geocoder_opencagedata'
require './wrappers/demo'


module AddokWrapper
  ADDOK_FRA = Wrappers::Addok.new('http://api-adresse.data.gouv.fr', 'france.kml')
  GOOGLE = Wrappers::RubyGeocoderGoogle.new
  HERE = Wrappers::RubyGeocoderHere.new
  OPENCAGEDATA = Wrappers::RubyGeocoderOpencagedata.new
  DEMO = Wrappers::Demo.new

  @@c = {
    product_title: 'Addock Wrapper geocoding API',
    product_contact: 'frederic@mapotempo.com',
    geocoders: {
      fra: ADDOK_FRA,
    },
    geocoder_fallback: DEMO,
    api_keys: ['demo']
  }
end
