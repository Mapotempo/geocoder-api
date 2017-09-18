# Copyright © Mapotempo, 2017
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


class Wrappers::RubyGeocoderEsriTest < Minitest::Test
  def test_geocodes_from_full_text
    rg = GeocoderWrapper::ESRI
    result = rg.geocodes([{query: '50 Bv de la Plage, Arcachon'}])
    assert 0 < result.size
    g = result[0][:properties][:geocoding]
    assert_equal 'Arcachon', g[:city]
  end

  def test_geocodes_from_part
    rg = GeocoderWrapper::ESRI
    result = rg.geocodes([{housenumber: '50', street: 'Bv de la Plage', city: 'Arcachon'}])
    assert 0 < result.size
    g = result[0][:properties][:geocoding]
    assert_equal 'Arcachon', g[:city]
    assert_equal 'house', g[:type]
  end

  def test_geocode_from_full_text
    rg = GeocoderWrapper::ESRI
    result = rg.geocode({query: 'ул. Неглинная, д.4, Москва, 109012'})
    assert 0 < result[:features].size
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'Москва', g[:city]
  end

  def test_geocode_from_part
    rg = GeocoderWrapper::ESRI
    result = rg.geocode({housenumber: '4', street: 'ул. Неглинная', city: 'Москва'})
    assert 0 < result[:features].size
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'Москва', g[:city]
  end

  def test_geocode_maybe_street
    rg = GeocoderWrapper::ESRI
    result = rg.geocode({maybe_street: ['App 6', 'Rue Fondaudege'], city: 'Bordeaux', country: 'France'})
    assert result
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'Bordeaux', g[:city]
    assert_equal 'Rue Fondaudège', g[:street]
  end

  def test_reverse
    rg = GeocoderWrapper::ESRI
    result = rg.reverse({lat: 42.89442, lng: -2.16792})
    assert_equal 1, result[:features].size
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'Alsasua', g[:city]
  end
end
