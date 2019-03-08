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
require 'border_patrol'


module Wrappers
  class Wrapper
    def initialize(cache, boundary = nil)
      @cache = cache
      if boundary
        @boundary = BorderPatrol.parse_kml(File.read(boundary))
      end
    end

    def geocode(params, limit = 10)
      raise NotImplementedError
    end

    def reverse?(lat, lng)
      if @boundary
        contains?(lat, lng)
      else
        true
      end
    end

    def reverse(params)
      raise NotImplementedError
    end

    def geocodes(list_params)
      list_params.collect{ |params|
        features = geocode(params, limit = 1)[:features]
        if features.size > 0
          features[0][:properties][:geocoding][:ref] = params['ref']
          features[0]
        else
          {
            properties: {
              geocoding: {
                ref: params['ref']
              }
            }
          }
        end
      }.select{ |p|
        !p.nil?
      }
    end

    def reverses(list_params)
      list_params.collect{ |params|
        features = reverse(params)[:features]
        if features.size > 0
          features[0][:properties][:geocoding][:ref] = params['ref']
          features[0]
        else
          {
            properties: {
              geocoding: {
                ref: params['ref']
              }
            }
          }
        end
      }.select{ |p|
        !p.nil?
      }
    end

    def complete(params, limit = 10)
      raise NotImplementedError
    end

    private

    def clean_params(params)
      if params[:country]
        if params[:country].strip.upcase == 'FRANCE' || params[:country].strip.upcase == 'FR' || params[:country].strip.upcase == 'FRA'
          params[:postcode] = '0' + params[:postcode] if params[:postcode] && params[:postcode].size == 4
        end
      end
      params
    end

    def flatten_query(params, with_country = true)
      #country field can be nil in case of bulk geocode
      country = params[:country].nil? ? '' : params[:country]
      if params[:query]
        with_country && !params[:query].include?(country) ? params[:query] + ' ' + country : params[:query]
      else
        params = clean_params params
        [params[:housenumber], params[:street], params[:postcode], params[:city], (country if with_country)].compact.join(' ')
      end
    end

    def contains?(lat, lng)
      if !lat.nil? && !lng.nil?
        @boundary.contains_point?(lng, lat)
      end
    end

    def gen_streets(params)
      (params[:street] && [params[:street]]) || params[:maybe_street] || [nil]
    end

    def streets_loop(params, max_by)
      if params.key?(:query)
        yield(params)
      else
        p = params.dup
        gen_streets(params).collect{ |street|
          p[:street] = street
          yield(p)
        }.max_by{ |r|
          max_by.call(r[1])
        } || [nil, []]
      end
    end

    protected

    def version(query = nil)
      GeocoderWrapper::version
    end
  end

end
