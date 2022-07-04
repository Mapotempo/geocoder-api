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
require './test/test_helper'

require './sanitizer/sanitizer'

class Sanitizer::SanitizerTest < Minitest::Test
  include Rack::Test::Methods

  def test_should_initialize
    assert sanitizer = Sanitizer::Sanitizer.new('./sanitizer/', './sanitizer/countryInfo.txt')
    assert_equal Sanitizer::Sanitizer, sanitizer.class
  end

  def test_should_sanitize_one_address_on_each_param
    address = 'Place Pey Berland Bordeaux'
    sanitizer = Sanitizer::Sanitizer.new('./sanitizer/', './sanitizer/countryInfo.txt')

    [:query, :street, :maybe_street].each do |key|
      unsanitized_address = build_random_address(address)
      sanitized_address = sanitizer.sanitize({key => unsanitized_address}, :fr)[key]
      assert_equal address, sanitized_address
    end

    addresses = []
    3.times { addresses.push(build_random_address(address)) }
    sanitizer.sanitize({query: addresses[0], street: addresses[1], maybe_street: [addresses[2]]}, :fr).each_value do |sanitized_address|
      assert_equal(sanitized_address.is_a?(Array) ? [address] : address, sanitized_address)
    end
  end

  def test_should_sanitize_depending_on_country
    sanitizer = Sanitizer::Sanitizer.new('./sanitizer/', './sanitizer/countryInfo.txt')
    address = 'Place Pey Berland Bordeaux'
    prefix = 'rez-de-chaussée '
    suffix = ' (à supprimer dans tous les cas)'

    # Different types for France
    assert_equal address, sanitizer.sanitize({query: prefix + address + suffix}, :fr)[:query]
    assert_equal address, sanitizer.sanitize({query: prefix + address + suffix}, :fra)[:query]
    assert_equal address, sanitizer.sanitize({query: prefix + address + suffix}, :france)[:query]
    assert_equal address, sanitizer.sanitize({query: prefix + address + suffix}, :FR)[:query]

    # For Italy french language is also accepted
    assert_equal address, sanitizer.sanitize({query: prefix + address + suffix}, :it)[:query]
    assert_equal address, sanitizer.sanitize({query: prefix + address + suffix}, :italy)[:query]

    # Countries without french language acceptance -> all only
    assert_equal prefix + address, sanitizer.sanitize({query: prefix + address + suffix}, :en)[:query]

    # None country -> all only
    assert_equal prefix + address, sanitizer.sanitize({query: prefix + address + suffix}, :xx)[:query]
  end

  def test_should_sanitize_missing_space
    sanitizer = Sanitizer::Sanitizer.new('./sanitizer/', './sanitizer/countryInfo.txt')
    address = 'Place Pey Berland Bordeaux'
    additional = '(chez papa)'
    suffix = 'digicode:A1234'

    assert_equal address, sanitizer.sanitize({query: address + additional + suffix}, :fr)[:query]
  end

  def test_should_sanitize_any_where
    sanitizer = Sanitizer::Sanitizer.new('./sanitizer/', './sanitizer/countryInfo.txt')
    address = 'Place Pey Berland Bordeaux'
    additional = 'chez papa'

    assert_equal address, sanitizer.sanitize({query: address + ' ' + additional}, :fr)[:query]
    assert_equal additional + ' ' + address, sanitizer.sanitize({query: additional + ' ' + address}, :fr)[:query]
  end

  private

  def build_random_address(address)
    return address if address.blank?

    elements = ['batiment D', '(au fond à droite)', 'lieu-dit', 'REZ-DE-CHAUSSéE',
                'bureau 10', 'Interphone', 'DIGICODE 1234', 'ESCALIER C', '4ème étage'].shuffle
    to_sanitize = []
    2.times { to_sanitize << elements.slice!(0..rand(0..elements.size)) }
    to_sanitize << elements

    elements = address.split(' ')
    to_keep = [elements.slice!(0..rand(0..elements.size)), elements]

    elements = to_sanitize[0] + to_keep[0] + to_sanitize[1] + to_keep[1] + to_sanitize[2]
    elements.join(' ')
  end
end
