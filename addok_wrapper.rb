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
module AddokWrapper
  def self.config
    @@c
  end

  def self.wrapper_geocode(params)
    country = self.geocode_country(params[:country])
    if @@c[:geocoders].key?(country)
      @@c[:geocoders][country].geocode(params, params[:limit])
    elsif @@c[:geocoder_fallback]
      @@c[:geocoder_fallback].geocode(params, params[:limit])
    end
  end

  def self.wrapper_reverse(params)
    wrapper = @@c[:geocoders].find{ |country, wrapper|
      wrapper.reverse?(params[:lat], params[:lng])
    }
    if !wrapper.nil?
      wrapper[1].reverse(params)
    elsif @@c[:geocoder_fallback]
      @@c[:geocoder_fallback].reverse(params)
    end
  end

  def self.wrapper_geocodes(list_params)
    by_country = list_params.group_by{ |params|
      self.geocode_country(params[:country])
    }
    by_country.collect{ |country, list_params|
      if @@c[:geocoders].key?(country)
        @@c[:geocoders][countryc].geocodes(list_params)
      elsif @@c[:geocoder_fallback]
        @@c[:geocoder_fallback].geocodes(list_params)
      end
    }.flatten(1)
  end

  def self.wrapper_reverses(list_params)
    list_params.group_by{ |params|
      @@c[:geocoders].find{ |country, wrapper|
        wrapper.reverse?(params[:lat], params[:lng])
      } || @@c[:geocoder_fallback]
    }.collect{ |wrapper, list_params|
      if !wrapper.nil?
        wrapper.reverses(list_params)
      end
    }.flatten(1)
  end

  def self.wrapper_complete(params)
    country = self.geocode_country(params[:country])
    if @@c[:geocoders].key?(country)
      @@c[:geocoders][country].complete(params, params[:limit])
    elsif @@c[:geocoder_fallback]
      @@c[:geocoder_fallback].complete(params, params[:limit])
    end
  end

  private

  def self.geocode_country(name)
    if ['france', 'fra', 'fr'].include?(name.strip.downcase)
      :fra
    end
  end
end
