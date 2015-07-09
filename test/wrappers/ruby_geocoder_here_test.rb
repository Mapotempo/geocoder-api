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
require './test/test_helper'

require './wrappers/ruby_geocoder_here'

class Wrappers::RubyGeocoderHereTest < Minitest::Test

  def test_geocode_from_full_text
    rg = Wrappers::RubyGeocoderHere.new
    result = rg.geocode({query: 'ул. Неглинная, д.4, Москва, 109012'})
    assert 0 < result[:features].size
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'Москва', g[:city]
  end

  def test_geocode_from_part
    rg = Wrappers::RubyGeocoderHere.new
    result = rg.geocode({housenumber: '4', street: 'ул. Неглинная', city: 'Москва'})
    assert 0 < result[:features].size
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'Москва', g[:city]
  end
end
