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


class Wrappers::RubyGeocoderHereTest < Minitest::Test

  def test_geocode_from_full_text
    rg = GeocoderWrapper::HERE
    result = rg.geocode({query: 'ул. Неглинная, д.4, Москва, 109012'})
    assert 0 < result[:features].size
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'Moscow', g[:city]
  end

  def test_geocode_from_part
    rg = GeocoderWrapper::HERE
    result = rg.geocode({housenumber: '4', street: 'ул. Неглинная', city: 'Москва'})
    assert 0 < result[:features].size
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'Moscow', g[:city]
  end

  def test_geocode_maybe_street
    rg = GeocoderWrapper::HERE
    result = rg.geocode({maybe_street: ['App 6', 'Rue Fondaudege'], city: 'Bordeaux', country: 'France'})
    assert result
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'Bordeaux', g[:city]
    assert_equal 'Rue Fondaudège', g[:street]
  end

  def test_complete
    rg = GeocoderWrapper::HERE
    result = rg.complete({query: 'ул. Неглинная, д.4, Мос'})
    assert 0 < result[:features].size
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'Moscow', g[:city]
  end

  def test_reverse
    rg = GeocoderWrapper::HERE
    result = rg.reverse({lat: 42.89442, lng: -2.16792})
    assert_equal 1, result[:features].size
    g = result[:features][0][:properties][:geocoding]
    assert_equal 'Alsasua', g[:city]
  end

  def test_return_geocoder_and_wrapper_version
    rg = GeocoderWrapper::HERE
    result = rg.geocode({city: 'Marseille', country: 'FR'}, limit = 1)
    v = result[:features][0][:properties][:geocoding][:geocoder_version]
    assert v.include? GeocoderWrapper::version
    assert v.include? 'here'
  end

  def test_geocodes_from_full_text
    rg = Wrappers::RubyGeocoderHere.new(GeocoderWrapper::CACHE, boundary = nil, min_length = 0)
    result = rg.geocodes([
      {query: ''},
      {query: 'ул. Неглинная, д.4, Москва, 109012'}
    ])
    assert_equal 2, result.size
    g = result[0][:properties][:geocoding]
    assert_equal 0, g.size
    g = result[1][:properties][:geocoding]
    assert_equal 'Москва', g[:city]
  end

  def test_reverses
    rg = Wrappers::RubyGeocoderHere.new(GeocoderWrapper::CACHE, boundary = nil, min_length = 0)
    result = rg.reverses([{lat: 42.89442, lng: -2.16792}])
    assert_equal 1, result.size
    g = result[0][:properties][:geocoding]
    assert_equal 'Alsasua', g[:city]
  end

  def test_reverses_no_result
    rg = Wrappers::RubyGeocoderHere.new(GeocoderWrapper::CACHE, boundary = nil, min_length = 0)
    result = rg.reverses([
      {lat: 0, lng: 0},
      {lat: 42.89442, lng: -2.16792},
    ])
    assert_equal 2, result.size
    g = result[0][:properties][:geocoding]
    assert_equal 0, g.size
    g = result[1][:properties][:geocoding]
    assert_equal 'Alsasua', g[:city]
  end
end if ENV['HERE_API']
