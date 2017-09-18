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
module GeocoderWrapper
  def self.config
    @@c
  end

  def self.wrapper_geocode(services, params)
    country = self.geocode_country(params[:country])
    if services[:geocoders].key?(country)
      services[:geocoders][country].geocode(params, params[:limit])
    elsif services[:geocoder_fallback]
      services[:geocoder_fallback].geocode(params, params[:limit])
    end
  end

  def self.wrapper_reverse(services, params)
    wrapper = services[:geocoders].find{ |country, wrapper|
      wrapper.reverse?(params[:lat], params[:lng])
    }
    if !wrapper.nil?
      wrapper[1].reverse(params)
    elsif services[:geocoder_fallback]
      services[:geocoder_fallback].reverse(params)
    end
  end

  def self.wrapper_geocodes(services, list_params)
    by_country = list_params.each_with_index.group_by{ |params, index|
      self.geocode_country(params[:country]) if params[:country]
    }
    by_country.collect{ |country, list_params|
      list_params.collect!{ |params, index|
        params[:index] = index
        params
      }
      results = if services[:geocoders].key?(country)
        services[:geocoders][country].geocodes(list_params)
      elsif services[:geocoder_fallback]
        services[:geocoder_fallback].geocodes(list_params)
      else
        []
      end
      results.each_with_index{ |result, i|
        result[:index] = list_params[i][:index]
        result[:properties][:geocoding][:source] = list_params[i]
      }
      results
    }.flatten(1).sort_by{ |params| params[:index] }
  end

  def self.wrapper_reverses(services, list_params)
    list_params.each_with_index.group_by{ |params, index|
      wrapper = services[:geocoders].find{ |country, wrapper|
        wrapper.reverse?(params[:lat], params[:lng])
      }
      (wrapper.nil? ? nil : wrapper[1]) || services[:geocoder_fallback]
    }.collect{ |wrapper, list_params|
      if !wrapper.nil?
        list_params.collect!{ |params, index|
          params[:index] = index
          params
        }
        results = wrapper.reverses(list_params)
        results.each_with_index{ |result, i|
          result[:index] = list_params[i][:index]
        }
        results
      end
    }.flatten(1).sort_by{ |params| params[:index] }
  end

  def self.wrapper_complete(services, params)
    country = self.geocode_country(params[:country])
    if services[:geocoders].key?(country)
      services[:geocoders][country].complete(params, params[:limit])
    elsif services[:geocoder_fallback]
      services[:geocoder_fallback].complete(params, params[:limit])
    end
  end

  private

  def self.geocode_country(name)
    if ['france', 'fra', 'fr'].include?(name.strip.downcase)
      :fra
    end
  end
end
