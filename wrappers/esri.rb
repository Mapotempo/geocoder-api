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
require './wrappers/wrapper'

#require 'rest-client'
#RestClient.log = $stdout


module Wrappers
  class Esri < Wrapper
    @@header = {
      type: 'FeatureCollection',
      geocoding: {
        licence: 'Esri',
        attribution: 'Esri',
        query: nil,
      },
      features: []
    }

    @@match_level = {
      'country' => 'country',
      'Admin' => 'state',
      'DepAdmin' => 'county',
      'SubAdmin' => 'city',
      'Locality' => 'locality',
      'Zone' => 'locality',
      'StreetName' => 'street',
      'StreetInt' => 'intersection',
      'StreetAddress' => 'house',
      'BuildingName' => 'house',
      'PointAddress' => 'house',
      'LatLong' => 'house',
      'RoadKM' => 'house',
      'PostalLoc' => 'postcode',
      'PostalExt' => 'postcode',
      'Postal' => 'postcode'
    }

    def initialize(oauth_client_id, oauth_client_secret, cache, boundary = nil)
      super(cache, boundary)
      @oauth_client_id = oauth_client_id
      @oauth_client_secret = oauth_client_secret
      @oauth_token = nil
      @url = 'http://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer'
    end

    def geocode(params, limit = 10)
      q, json = streets_loop(params, ->(r) { r && r['candidates'] && r['candidates'].size > 0 && r['candidates'][0]['score'] || 0 }) { |params|
        key_params = {limit: limit}.merge(params).reject{ |k, v| k == 'api_key' }
        key = [:esri, :geocode, Digest::MD5.hexdigest(Marshal.dump(key_params.to_a.sort_by{ |i| i[0].to_s }))]

        json = @cache.read(key)
        if !json
          # https://developers.arcgis.com/rest/geocode/api-reference/geocoding-find-address-candidates.htm
          p = {
            forStorage: @oauth_client_id && true || nil,
            f: :json,
            maxLocations: limit,
            outFields: 'X,Y,address,Score,Addr_type,AddNum,StAddr,Postal,City,Subregion,Region,Country',
            # langCode: 'fr' # TODO
          }

          if params[:query]
            p[:singleLine] = [params[:query], params[:country]].join(' ')
            p[:category] = 'Address,Postal,Populated Place'
          else
            params = clean_params params
            p[:address] = [params[:housenumber], params[:street]].compact.join(' ')
            p[:neighborhood] = params[:locality]
            p[:postal] = params[:postcode]
            p[:city] = params[:city]
            p[:countryCode] = params[:country]
            p[:category] = p[:address] && p[:address] != '' ? 'Address' : 'Postal,Populated Place'
          end

          if params[:lat] && params[:lng]
            p[:location] = [params[:lng], params[:lat]].join(',')
            p[:distance] = 32000000 # Full planet in meters
          end

          with_oauth{ |token|
            response = RestClient.get(@url + '/findAddressCandidates', {params: p.merge(token: token)}) { |response, request, result, &block|
              case response.code
              when 200
                response
              else
                raise response
              end
            }

            json = JSON.parse(response)
            if json.key?('error')
              if [498, 499].include?(json['error']['code'])
                raise EsriOAuthTokenError.new
              else
                raise json['error']['message']
              end
            end
            @cache.write(key, json)
          }
        end

        [nil, json]
      }

      geojson = @@header.dup
      geojson[:geocoding][:query] = params[:query] || flatten_query(params)
      geojson[:features] = json['candidates'] && json['candidates'].collect{ |a| {
        properties: {
          geocoding: {
            geocoder_version: version,
            score: a['score'] / 100 * 0.9,
            type: @@match_level[a['attributes']['Addr_type']],
            label: a['address'],
#            name: a['StAddr'], ############" or or or
            housenumber: a['attributes']['AddNum'],
            street: a['attributes']['StAddr'],
            postcode: [a['address']['Postal'], a['address']['PostalExt']].compact.join(' '),
            city: a['attributes']['City'],
#             district: a['attributes']['Subregion'],
            county: a['attributes']['Subregion'],
            state: a['attributes']['Region'],
            country: a['attributes']['Country'],
          }.delete_if{ |k, v| v.nil? || v == '' }
        },
        type: 'Feature',
        geometry: {
          coordinates: [
            a['location']['x'],
            a['location']['y']
          ],
          type: 'Point'
        }
      }} || []

      geojson
    end

    GEOCODES_SLICE_SIZE = 100

    def geocodes(list_params)
      slice_number = list_params.size / GEOCODES_SLICE_SIZE
      list_params.each_slice(GEOCODES_SLICE_SIZE).each_with_index.collect{ |slice_params, slice|
        requests = []
        results = Hash.new{ |h, k| h[k] = [] }
        slice_params.each_with_index.collect{ |param, index|
          key = [:esri, :geocodes, Digest::MD5.hexdigest(Marshal.dump(param.to_a.sort_by{ |i| i[0].to_s }))]
          r = @cache.read(key)
          if !r
            p = {
              OBJECTID: index * 1000
            }

            if param[:lat] && param[:lng]
              p[:location] = [param[:lng], param[:lat]].join(',')
              p[:distance] = 32000000 # Full planet in meters
            end

            if param[:query]
              requests << p.merge({
                singleLine: [param[:query], param[:country]].join(' '),
                category: 'Address,Postal,Populated Place'
              })
            else
              param = clean_params param
              requests += gen_streets(param).each_with_index.collect{ |street, subindex|
                p.dup.merge({
                  OBJECTID: p[:OBJECTID] + subindex,
                  street: street,
                  address: [param[:housenumber], param[:street]].compact.join(' '),
                  neighborhood: param[:locality],
                  postal: param[:postcode],
                  city: param[:city],
                  countryCode: param[:country],
                  category: param[:housenumber] || param[:street] ? 'Address' : 'Postal,Populated Place'
                }.delete_if{ |k, v| v.nil? || v == '' })
              }
            end
          else
            results[index] = [r]
          end

          data = {
            records: requests.collect{ |p| {
              attributes: p
            }}
          }

          # https://developers.arcgis.com/rest/geocode/api-reference/geocoding-geocode-addresses.htm
          json = with_oauth{ |token|
            response = RestClient.post(@url + '/geocodeAddresses', {forStorage: true, token: token, f: :json, addresses: data.to_json}, {content_type: :json, accept: :json}) { |response, request, result, &block|
              case response.code
              when 200
                response
              else
                raise response
              end
            }

            json = JSON.parse(response)
            if json.key?('error')
              # Terminate the batch geocoding process
              if [498, 499].include?(json['error']['code'])
                raise EsriOAuthTokenError.new
              else
                raise json['error']['message']
              end
            end

            json
          }

          if json.key?('locations')
            json['locations'].each{ |a|
              results[a['attributes']['ResultID']] << a
            }
            results = Hash[results.collect{ |k, v|
              [(k / 1000).to_i, v.max_by{ |r| r['score'] }]
            }]

            slice_params.each_with_index.collect{ |param, index|
              a = results[index]
              a && {
                properties: {
                  geocoding: {
                    geocoder_version: version,
                    ref: param[:ref],
                    score: a['score'] / 100 * 0.9,
                    type: @@match_level[a['attributes']['Addr_type']],
                    label: a['address'],
#                    name: a['StAddr'], ############" or or or
                    housenumber: a['attributes']['AddNum'],
                    street: a['attributes']['StAddr'],
                    postcode: [a['address']['Postal'], a['address']['PostalExt']].compact.join(' '),
                    city: a['attributes']['City'],
#                     district: a['attributes']['Subregion'],
                    county: a['attributes']['Subregion'],
                    state: a['attributes']['Region'],
                    country: a['attributes']['Country'],
                  }.delete_if{ |k, v| v.nil? || v == '' }
                },
                type: 'Feature',
                geometry: {
                  coordinates: [
                    a['location']['x'],
                    a['location']['y']
                  ],
                  type: 'Point'
                }
              }
            } || {}
          end
        }.compact
      }.flatten(2)
    end

    def reverse(params)
      key_params = params.reject{ |k, v| k == 'api_key' }
      key = [:esri, :reverse, Digest::MD5.hexdigest(Marshal.dump(key_params.to_a.sort_by{ |i| i[0].to_s }))]

      json = @cache.read(key)
      if !json
        # https://developers.arcgis.com/rest/geocode/api-reference/geocoding-reverse-geocode.htm
        p = {
          forStorage: @oauth_client_id && true || nil,
          f: :json,
          outFields: 'X,Y,address,Score,Addr_type,AddNum,StAddr,Postal,City,Subregion,Region,Country',
          # langCode: 'fr', # TODO
          location: [params[:lng], params[:lat]].join(',')
        }

        with_oauth{ |token|
          response = RestClient.get(@url + '/reverseGeocode', {params: p.merge(token: token)}) { |response, request, result, &block|
            case response.code
            when 200
              response
            else
              raise response
            end
          }
          json = JSON.parse(response)
          if json.key?('error')
            if [498, 499].include?(json['error']['code'])
              raise EsriOAuthTokenError.new
            else
              raise json['error']['message']
            end
          end
          @cache.write(key, json)
        }
      end

      a = json['address']
      geojson = @@header.dup
      geojson[:features] = a && [{
        properties: {
          geocoding: {
            geocoder_version: version,
#            type: @@match_level[a['Addr_type']],
            label: a['Match_addr'],
#            name: a['StAddr'], ############" or or or
#            housenumber: a['AddNum'],
            street: a['Address'],
            postcode: [a['Postal'], a['PostalExt']].compact.join(' '),
            city: a['City'],
#            district: a['Subregion'],
            county: a['Subregion'],
            state: a['Region'],
            country: a['CountryCode'],
          }.delete_if{ |k, v| v.nil? || v == '' }
        },
        type: 'Feature',
        geometry: {
          coordinates: [
            json['location']['x'],
            json['location']['y']
          ],
          type: 'Point'
        }
      }] || []

      geojson
    end

    def version(query = nil)
      "#{super} - esri"
    end

    private

    def fetch_oauth_token
      params = {
        f: :json,
        client_id: @oauth_client_id,
        client_secret: @oauth_client_secret,
        grant_type: :client_credentials
      }
      response = RestClient.post('https://www.arcgis.com/sharing/rest/oauth2/token', params, {accept: :json}) { |response, request, result, &block|
        case response.code
        when 200
          response
        else
          raise response
        end
      }

      JSON.parse(response)['access_token']
    end

    def with_oauth
      [1..2].each{ |i|
        begin
          return yield(@oauth_token ||= fetch_oauth_token)
          # Break the loop with return if there is no exception
        rescue EsriOAuthTokenError
          @oauth_token = nil
        end
      }
    end
  end

  class EsriOAuthTokenError
  end
end
