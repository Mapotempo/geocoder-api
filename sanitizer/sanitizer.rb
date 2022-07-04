# Copyright © Mapotempo, 2022
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
require 'yaml'

module Sanitizer
  class Sanitizer
    def initialize(rules_path, country_info)
      @rules = Dir.glob("#{rules_path}*.yaml").map do |rules_file|
        [rules_file.gsub(/country_|.*\/|.yaml$/, ''), load_rules(rules_file)]
      end.to_h
      @country_info = country_info
      @country_languages = load_country_languages
      @rules_by_country = {}
    end

    def sanitize(params, country)
      [:query, :street, :maybe_street].each do |field|
        next unless params[field].present?

        if params[field].is_a? Array
          params[field].map!{ |prm| sanitize_param(prm, country) }
        else
          params[field] = sanitize_param(params[field], country)
        end
      end

      params
    end

    private

    def sanitize_param(param, country)
      return unless param

      param.gsub!(':', ' ') # To simplify matching rules regexp with "digicode: 1234"
      matching_rules(country).reduce(param) { |text, rule|
        text.gsub(/\s{2,}/, ' ').gsub(rule, ' ')
      }.strip
    end

    def load_rules(rules_file)
      rules = YAML.safe_load(File.read(rules_file))

      (rules.try(:[], 'any_where') || []).map{ |rule| Regexp.new(rule, 'i') } +
        (rules.try(:[], 'on_word_bounds') || []).map{ |rule| Regexp.new('\b' + rule + '\b', 'i') }
    end

    def matching_rules(country)
      country_code = matching_country(country)
      @rules_by_country[country_code] ||= matching_rules_by_country(country_code)
    end

    def matching_country(country)
      load_country_info.find do |row|
        [row[0], row[1], row[4]].map(&:downcase).include?(country.to_s.downcase)
      end&.first
    end

    def load_country_info
      @load_country_info ||= CSV.read(@country_info, col_sep: "\t").select do |row|
        row[0][0] != '#' && row[15]
      end
    end

    def matching_rules_by_country(country)
      (['all', country] + (@country_languages[country] || [])).flat_map{ |key| @rules[key] }.compact
    end

    def load_country_languages
      load_country_info.collect do |row|
        [row[0], row[15].split(',').map{ |locale| locale.gsub(/\-.+/, '') }]
      end.to_h
    end
  end
end
