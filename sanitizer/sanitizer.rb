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
      @country_info = country_info
      @country_languages = load_country_languages
      @rules_by_country = {}
    end

    def sanitize(params, country)
      [:query, :street, :maybe_street].each{ |field|
        params[field] = matching_rules(country).reduce(params[field]) { |text, rule|
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

    def matching_rules(country)
      country_code = matching_country(country)
      @rules_by_country[country_code] ||= matching_rules_by_country(country_code)
    end

    def matching_country(country)
      load_country_info.find{ |row|
        row[0].downcase.to_sym == country || row[1].downcase.to_sym == country || row[4].downcase.to_sym == country
      }.try(:[], 0)
    end

    def load_country_info
      @load_country_info ||= CSV.read(@country_info, col_sep: "\t").select{ |row|
        row[0][0] != '#' && row[15]
      }
    end

    def matching_rules_by_country(country)
      keys = ['all', country] + (@country_languages[country] || [])
      keys.flat_map{ |key| @rules[key] }.compact
    end

    def load_country_languages
      Hash[load_country_info.collect{ |row|
        [row[0], row[15].split(',').map{ |locale| locale.gsub(/\-.+/, '') }]
      }]
    end
  end
end
