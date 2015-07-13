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
require './wrappers/wrapper'

require 'geocoder'

module Wrappers
  class RubyGeocoderHere < Wrapper
    @@header = {
      'type': 'FeatureCollection',
      'geocoding': {
        'licence': 'HERE',
        'attribution': 'HERE',
        'query': nil,
      },
      'features': []
    }


    def initialize(boundary = nil)
      super(boundary)
#      Geocoder.configure(lookup: :here,
# FIXME
#  here: {
#    api_key: ['yihiGwg1ibLi0q6BfBOa', '5GEGWZnjPAA-ZIwc7DF3Mw']
#  }
#)
    end

    def geocode(params, limit = 10)
      q = flatten_query(params)
      Geocoder::Configuration.lookup = :here
      Geocoder::Configuration.api_key = ::AddokWrapper::config[:ruby_geocode][Geocoder::Configuration.lookup]
      response = Geocoder.search(q, params: {maxresults: limit})
      #Geocoder.search(nil, params: {maxresults: limit, city: params[:city], district: params[:district], housenumber: params[:housenumber], postalcode: params[:postcode], state: params[:state], street: params[:street]})
      features = response.collect{ |r|
        a = r.data
        # https://developer.here.com/rest-apis/documentation/geocoder/topics/resource-type-response-geocode.html
        additional_data = parse_address_additional_data(a['Location']['Address']['AdditionalData'])
        {
          'properties': {
            'geocoding': {
              'score': a['Relevance'],
              'type': a['LocationType'], # TODO map to common value
              'label': a['Location']['Address']['Label'],
              'name': a['Location']['Address']['Name'],
              'housenumber': [a['Location']['Address']['HouseNumber'], a['Location']['Address']['Building']].select{ |i| i }.join(' '),
              'street': a['Location']['Address']['Street'],
              'postcode': a['Location']['Address']['PostalCode'],
              'city': a['Location']['Address']['City'],
              #'district': a['Location']['Address']['District'], # In HERE API district is a city district
              'county': additional_data['CountyName'],
              'state': additional_data['StateName'],
              'country': additional_data['CountryName'],
            }
          },
          'type': 'Feature',
          'geometry': {
            'coordinates': [
              a['Location']['DisplayPosition']['Longitude'],
              a['Location']['DisplayPosition']['Latitude']
            ],
            'type': 'Point'
          }
        }
      }

      r = @@header.dup
      r[:geocoding][:query] = q
      r[:features] = features
      r
    end

    #def reverse(params)
    #end

    private

    def parse_address_additional_data(additional_data)
      h = Hash.new{ |h, k| h[k] = nil }
      additional_data.each{ |ad|
        h[ad['key']] = ad['value']
      }
      h
    end
  end
end