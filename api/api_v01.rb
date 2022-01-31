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
require 'grape'
require 'grape-swagger'

require './api/v01/api'

module Api
  class ApiV01 < Grape::API
    version '0.1', using: :path

    content_type :json, 'application/json; charset=UTF-8'
    content_type :geojson, 'application/vnd.geo+json; charset=UTF-8'
    content_type :xml, 'application/xml'
    content_type :csv, 'text/csv; charset=UTF-8'

    mount V01::Api

    documentation_class = add_swagger_documentation(
      hide_documentation_path: true,
      security_definitions: {
        api_key_query_param: {
          type: 'apiKey',
          name: 'api_key',
          in: 'query'
        }
      },
      security: [{
        api_key_query_param: [],
      }],
      consumes: [
        'application/json; charset=UTF-8',
        'application/xml',
      ],
      produces: [
        'application/json; charset=UTF-8',
        'application/vnd.geo+json; charset=UTF-8',
        'application/xml',
      ],
      doc_version: nil,
      info: {
        title: ::GeocoderWrapper::config[:product_title],
        contact_email: ::GeocoderWrapper::config[:product_contact_email],
        contact_url: ::GeocoderWrapper::config[:product_contact_url],
        license: 'GNU Affero General Public License 3',
        license_url: 'https://raw.githubusercontent.com/Mapotempo/geocoder-api/master/LICENSE',
        description: '
## Technical access

### Swagger descriptor

This REST API is described with Swagger. The Swagger descriptor defines the request end-points, the parameters and the return values. The API can be addressed by HTTP request or with a generated client using the Swagger descriptor.

### API key

All access to the API are subject to an `api_key` parameter in order to authenticate the user.
Usage: `http://geocode.mapotempo.com/0.1/geocode?api_key=***`

### Return

API results are geojson extended by geocodejson-spec on version draft#namespace#score.

### Javascript sdk

A Javascript sdk `map.js?api_key=***` is available to display geocoded result on a map. See examples below.
Default base map layer tiles are provided by Open Street Map with [usage limitations](https://operations.osmfoundation.org/policies/tiles/).
Other map layers are availables if you need.

## Examples

### Geocode

[Geocode full text address](http://geocode.mapotempo.com/geocode.html)

### Reverse geocode

[Get address from lat/lng](http://geocode.mapotempo.com/reverse.html)
        '
      }
    )
  end
end
