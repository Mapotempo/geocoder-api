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
      @rules = Hash[Dir.glob(rules_path + '*.yaml').collect{ |rules_file|
        [rules_file.gsub(/.*\//, '').gsub(/.yaml$/, ''), load_rules(rules_file)]
      }]
      @country_languages = load_country_languages(country_info)
      @rules_by_country = {}
    end

    def sanitize(params)
      [:query, :street, :maybe_street].each{ |field|
        params[field] = matching_rules(params).reduce(params[field]) { |text, rule|
          text.gsub(rule, '')
        } if params[field]
      }
      params
    end

    private

    def load_rules(rules_file)
      rules = YAML.load(File.read(rules_file))

      (rules && rules['any_where'] || []).collect{ |rule|
        # Use regex as is
        Regexp.new(rule, 'i')
      } + (rules && rules['on_word_bounds'] || []).collect{ |rule|
        # Bound regex with \b (word sperator)
        Regexp.new('\b' + rule + '\b', 'i')
      }
    end

    def matching_rules(params)
      country = params[:country]
      @rules_by_country[country] ||= matching_rules_by_country(country)
    end

    def matching_rules_by_country(country)
      keys = ['all', country] + (@country_languages[country] || [])
      keys.flat_map{ |key| @rules[key] }.compact
    end

    def load_country_languages(country_info)
      Hash[CSV.read(country_info, col_sep: "\t").select{ |row|
        row[0][0] != '#' && row[15]
      }.collect{ |row|
        [row[0], row[15].split(',')]
      }]
    end
  end
end
