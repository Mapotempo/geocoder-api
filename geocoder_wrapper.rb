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

  def self.access(force_load = false)
    load config[:access_by_api_key][:file] || './config/access.rb' if force_load
    @access_by_api_key
  end

  def self.release
    @release
  end

  def self.wrapper_geocode(services, params)
    country = self.geocode_country(params[:country])
    service = services[:geocoders].key?(country) ? services[:geocoders][country] : services[:geocoder_fallback]
    params = self.config[:sanitizer].sanitize(params) if params[:sanitize_address]
    service.geocode(params, params[:limit])
  end

  def self.wrapper_reverse(services, params)
    wrapper = services[:geocoders].find{ |_, w| w.reverse?(params[:lat], params[:lng]) }

    if !wrapper.nil?
      wrapper[1].reverse(params)
    elsif services[:geocoder_fallback]
      services[:geocoder_fallback].reverse(params)
    end
  end

  def self.wrapper_geocodes(services, list_params)
    by_country = list_params.each_with_index.group_by do |params, _|
     self.geocode_country(params[:country]) if params[:country]
    end
    geocode_results = by_country.flat_map do |country, params_list|
      params_list.collect! do |params, index|
        params[:index] = index
        params
      end

      service = services[:geocoders].key?(country) ? services[:geocoders][country] : services[:geocoder_fallback]
      results = if service
        params_list = params_list.collect{ |params|
          params[:sanitize_address] ? self.config[:sanitizer].sanitize(params) : params
        }
        service.geocodes(params_list)
      else
        []
      end

      results.each_with_index do |result, i|
        result[:index] = params_list[i] && params_list[i][:index]
        result[:properties][:geocoding][:source] = params_list[i]
      end
    end

    geocode_results.sort_by{ |params| params[:index] }
  end

  def self.wrapper_reverses(services, list_params)
    grouped_params = list_params.each_with_index.group_by do |params, _|
      wrapper = services[:geocoders].find { |_, w| w.reverse?(params[:lat], params[:lng]) }
      (wrapper.nil? ? nil : wrapper[1]) || services[:geocoder_fallback]
    end

    reverse_results = grouped_params.flat_map do |w, params_list|
      unless w.nil?
        params_list.collect! do |params, index|
          params[:index] = index
          params
        end
        results = w.reverses(params_list)
        results.each_with_index{ |result, i| result[:index] = params_list[i][:index] }
        results
      end
    end

    reverse_results.sort_by{ |params| params[:index] }
  end

  def self.wrapper_complete(services, params)
    country = self.geocode_country(params[:country])

    service = services[:geocoders].key?(country) ? services[:geocoders][country] : services[:geocoder_fallback]
    params = self.config[:sanitizer].sanitize(params) if params[:sanitize_address]
    service.complete(params, params[:limit])
  end

  def self.version
    'Wrapper:1.1.1' # Update changelog.txt
  end

  def self.geocode_country(name)
    if %w[france fra fr].include?(name.strip.downcase)
      :fra
    elsif %w[luxembourg luxemburg lux lu].include?(name.strip.downcase)
      :lux
    else
      name.downcase.to_sym
    end
  end
end
