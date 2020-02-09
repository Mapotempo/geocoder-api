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
  include FakeRedis

  def app
    Api::Root
  end

  def test_geocodes_from_full_text
    post '/0.1/geocode', {api_key: 'demo', geocodes: [{ref: '33', query: 'Place Pey Berland, Bordeaux', country: 'ttt'}]}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['geocodes']
    assert 0 < features.size
    assert_equal '33', features[0]['properties']['geocoding']['ref']
  end

  def test_geocodes_from_fields
    post '/0.1/geocode', {api_key: 'demo', geocodes: [{street: 'Place Pey Berland', city: 'Bordeaux', country: 'ttt'}]}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['geocodes']
    assert 0 < features.size
  end

  def test_geocodes_without_country
    post '/0.1/geocode', {api_key: 'demo', geocodes: [{query: 'Place Pey Berland, Bordeaux'}]}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['geocodes']
    assert_equal 1, features.size
  end

  def test_reverses
    post '/0.1/reverse', {api_key: 'demo', reverses: [{ref: '33', lat: 0.1, lng: 0.1}]}
    assert last_response.ok?, last_response.body
    features = JSON.parse(last_response.body)['reverses']
    assert_equal 1, features.size
    assert_equal '33', features[0]['properties']['geocoding']['ref']
  end

  def test_geocodes_order
    post '/0.1/geocode', {api_key: 'demo', geocodes: [
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

  def test_reverses_order
    post '/0.1/reverse', {api_key: 'demo', reverses: [
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

  def test_geocodes_should_fail
    post '/0.1/geocode', {api_key: 'demo', geocodes: 'plop'}
    assert !last_response.ok?, last_response.body
  end

  def test_params_dont_exceed_limit
    post '/0.1/geocode', {api_key: 'bulk_limit', geocodes: [
      {query: 'NYC', country: 'ttt'},
    ]}
    assert last_response.ok?, last_response.body

    post '/0.1/reverse', {api_key: 'bulk_limit', reverses: [
      {lat: 0.1, lng: 0.1},
    ]}
    assert last_response.ok?, last_response.body
  end

  def test_params_exceed_limit
    post '/0.1/geocode', {api_key: 'bulk_limit', geocodes: [
      {query: 'NYC', country: 'ttt'},
      {query: 'Bordeaux', country: 'ttt'},
      {query: 'Rome', country: 'ttt'},
    ]}
    assert_equal 413, last_response.status
    assert JSON.parse(last_response.body)['message'].include? 'Exceeded "geocodes" limit'

    post '/0.1/reverse', {api_key: 'bulk_limit', reverses: [
      {lat: 0.1, lng: 0.1},
      {lat: 46.03349, lng: 4.07271},
      {lat: 0.2, lng: 0.2},
    ]}
    assert_equal 413, last_response.status
    assert JSON.parse(last_response.body)['message'].include? 'Exceeded "reverses" limit'
  end

  def test_count_geocodes
    (1..2).each do |i|
      post '/0.1/geocode', {api_key: 'demo', geocodes: [
        {query: 'NYC', country: 'ttt'},
        {query: 'Bordeaux', country: 'ttt'},
        {query: 'Rome', country: 'ttt'},
      ]}
      keys = GeocoderWrapper.config[:redis_count].keys("geocoder:geocode:#{Time.now.utc.to_s[0..9]}_key:demo_ip*")
      assert_equal 1, keys.size
      keys.each{ |key|
        assert_equal({'hits' => "#{i}", 'transactions' => "#{i*3}"}, GeocoderWrapper.config[:redis_count].hgetall(key))
      }
    end
  end

  def test_count_reverses
    (1..2).each do |i|
      post '/0.1/reverse', {api_key: 'demo', reverses: [
        {lat: 0.1, lng: 0.1},
        {lat: 46.03349, lng: 4.07271},
        {lat: 0.2, lng: 0.2},
      ]}
      keys = GeocoderWrapper.config[:redis_count].keys("geocoder:reverse:#{Time.now.utc.to_s[0..9]}_key:demo_ip*")
      assert_equal 1, keys.size
      keys.each{ |key|
        assert_equal({'hits' => "#{i}", 'transactions' => "#{i*3}"}, GeocoderWrapper.config[:redis_count].hgetall(key))
      }
    end
  end

  def test_use_quotas
    post '/0.1/geocode', {api_key: 'bulk_limit', geocodes: [
      {query: 'NYC', country: 'ttt'},
      {query: 'Bordeaux', country: 'ttt'},
    ]}
    assert last_response.ok?, last_response.body
    post '/0.1/geocode', {api_key: 'bulk_limit', geocodes: [
      {query: 'NYC', country: 'ttt'},
      {query: 'Bordeaux', country: 'ttt'},
    ]}
    assert_equal 429, last_response.status
    assert JSON.parse(last_response.body)['message'].include?('Too many monthly requests')
    assert_equal({ "Content-Type" => "application/json; charset=UTF-8",
                   "X-RateLimit-Limit" => 2,
                   "X-RateLimit-Remaining" => 0,
                   "X-RateLimit-Reset" => Time.now.utc.to_date.next_month.to_time.to_i }, last_response.headers)
  end
end
