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

class Wrappers::RubyGeocoderOpencagedataTest < Minitest::Test

  def test_geocode_from_full_text
    rg = GeocoderWrapper::OPENCAGEDATA
    result = rg.geocode({query: '1 Front Street, NYC'})
    assert 0 < result[:features].size
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'New York City', g[:city]
    assert_equal 'house', g[:type]
  end

  def test_geocode_from_part
    rg = GeocoderWrapper::OPENCAGEDATA
    result = rg.geocode({street: 'Via del Parlamento', city: 'Roma'})
    assert 0 < result[:features].size
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'Rome', g[:city]
    assert_equal 'street', g[:type]
  end

  def test_geocode_maybe_street
    rg = GeocoderWrapper::OPENCAGEDATA
    result = rg.geocode({maybe_street: ['App 6', 'Rue Fondaudege'], city: 'Bordeaux', country: 'France'})
    assert result
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'Bordeaux / Bordèu', g[:city]
    assert_equal 'Rue Fondaudège', g[:street]
  end

  def test_reverse
    rg = GeocoderWrapper::OPENCAGEDATA
    result = rg.reverse({lat: 42.90360, lng: -2.17306})
    assert_equal 1, result[:features].size
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'Altsasu/Alsasua', g[:city]
  end

  def test_return_geocoder_and_wrapper_version
    rg = GeocoderWrapper::OPENCAGEDATA
    result = rg.geocode({city: 'Marseille', country: 'FR'}, limit = 1)
    v = result[:features][0][:properties][:geocoding][:geocoder_version]
    assert v.include? GeocoderWrapper::version
    assert v.include? 'opencagedata'
  end
end if ENV['OPENCAGE_API']
