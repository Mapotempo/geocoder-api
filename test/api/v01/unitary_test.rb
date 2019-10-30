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

require './api/root'

class Api::V01::UnitaryTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Api::Root
  end

  def test_geocode_from_full_text
    _test_geocode_from_full_text('demo')
    _test_geocode_from_full_text('fra')
  end

  def test_should_geocode_from_fields
    _test_should_geocode_from_fields('demo')
    _test_should_geocode_from_fields('fra')
  end

  def test_should_not_geocode_without_country
    get '/0.1/geocode', {api_key: 'demo', query: 'Place Pey Berland, Bordeaux'}
    assert !last_response.ok?, last_response.body
  end

  def test_should_not_geocode_without_query_or_city
    get '/0.1/geocode', {api_key: 'demo', country: 'France'}
    assert !last_response.ok?, last_response.body
  end

  def test_should_not_geocode_with_query_and_city
    get '/0.1/geocode', {api_key: 'demo', query: 'Place Pey Berland', city: 'Bordeaux'}
    assert !last_response.ok?, last_response.body
  end

  def test_should_geocode_with_maybe_street
    get '/0.1/geocode', {api_key: 'demo', maybe_street: ['foo', 'bar', 'Place Pey Berland'], city: 'Bordeaux', country: 'demo'}
    assert last_response.ok?, last_response.body
  end

  def test_should_reverse
    _test_should_reverse(0, 0)
    _test_should_reverse(46.57698, 0.33421)
  end

  def test_should_complete
    _test_should_complete('demo')
    _test_should_complete('fra')
  end

  def test_geocode_limit
    _test_geocode_limit('demo')
    _test_geocode_limit('fra')
  end

  def test_geocode_encoding
    _test_geocode_encoding('demo')
    _test_geocode_encoding('fra')
  end

  def test_geocode_addok_missing_query
    get '/0.1/geocode', {api_key: 'demo', query: '', country: 'fr', limit: 2}
    assert_equal last_response.status, 400
    assert_equal "query is empty", JSON.parse(last_response.body)["message"]
  end

  private

  def _test_geocode_from_full_text(country)
    get '/0.1/geocode', {api_key: 'demo', query: 'Place Pey Berland, Bordeaux', country: country}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['features']
    assert 0 < features.size
  end

  def _test_should_geocode_from_fields(country)
    get '/0.1/geocode', {api_key: 'demo', street: 'Place Pey Berland', city: 'Bordeaux', country: country}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['features']
    assert 0 < features.size
  end

  def _test_should_reverse(lat, lng)
    get '/0.1/reverse', {api_key: 'demo', lat: lat, lng: lng}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['features']
    assert 0 < features.size
  end

  def _test_should_complete(country)
    patch '/0.1/geocode', {api_key: 'demo', query: 'Place Pey, Bordeaux', country: country}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['features']
    assert 0 < features.size
  end

  def _test_geocode_limit(country)
    get '/0.1/geocode', {api_key: 'demo', query: 'Rue des Rosiers', country: country, limit: 2}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['features']
    assert_equal 2, features.size
  end

  def _test_geocode_encoding(country)
    get '/0.1/geocode', {api_key: 'demo', query: 'Armentières', country: country, limit: 1}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['features']
    assert_equal 'Armentières', features[0]['properties']['geocoding']['city']
  end
end
