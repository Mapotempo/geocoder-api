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

class Api::V01::BulkTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Api::Root
  end

  def test_geocodes_from_full_text
    post '/0.1/geocodes', {api_key: 'demo', geocodes: [{ref: '33', query: 'Place Pey Berland, Bordeaux', country: 'ttt'}]}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['geocodes']
    assert 0 < features.size
    assert_equal '33', features[0]['properties']['geocoding']['ref']
  end

  def test_should_geocodes_from_fields
    post '/0.1/geocodes', {api_key: 'demo', geocodes: [{street: 'Place Pey Berland', city: 'Bordeaux', country: 'ttt'}]}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['geocodes']
    assert 0 < features.size
  end

  def test should_not_geocodes_without_country
    post '/0.1/geocodes', {api_key: 'demo', geocodes: [{query: 'Place Pey Berland, Bordeaux'}]}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['geocodes']
    assert_equal 0, features.size
  end

  def test_should_reverses
    post '/0.1/reverses', {api_key: 'demo', reverses: [{ref: '33', lat: 0.1, lng: 0.1}]}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['reverses']
    assert_equal 1, features.size
    assert_equal '33', features[0]['properties']['geocoding']['ref']
  end

  def test_geocodes_order
    post '/0.1/geocodes', {api_key: 'demo', geocodes: [
      {query: 'NYC', country: 'ttt'},
      {query: 'Bordeaux', country: 'France'},
      {query: 'Rome', country: 'ttt'},
    ]}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['geocodes']
    assert_equal 3, features.size
    assert_equal 'Armentières', features[0]['properties']['geocoding']['city'] # From Demo wrapper
    assert_equal 'Bordeaux', features[1]['properties']['geocoding']['city']
    assert_equal 'Armentières', features[2]['properties']['geocoding']['city'] # From Demo wrapper
  end

  def test_should_reverses_oder
    post '/0.1/reverses', {api_key: 'demo', reverses: [
      {lat: 0.1, lng: 0.1},
      {lat: 46.03349, lng: 4.07271},
      {lat: 0.2, lng: 0.2},
    ]}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['reverses']
    assert_equal 3, features.size
    assert_equal 'Armentières', features[0]['properties']['geocoding']['city'] # From Demo wrapper
    assert_equal 'Roanne', features[1]['properties']['geocoding']['city']
    assert_equal 'Armentières', features[2]['properties']['geocoding']['city'] # From Demo wrapper
  end
end
