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

  def test_constructor
    all = Sanitizer::Sanitizer.new('./test/sanitizer/', './sanitizer/countryInfo.txt')
    assert all
  end

  def test_sanitize_one
    all = Sanitizer::Sanitizer.new('./test/sanitizer/', './sanitizer/countryInfo.txt')
    assert all

    sanitized = all.sanitize({query: 'Place Pey Berland, Bordeaux (au fond à droite)'})[:query]
    assert_equal 'Place Pey Berland, Bordeaux ', sanitized
  end

  def test_sanitize_multi
    all = Sanitizer::Sanitizer.new('./test/sanitizer/', './sanitizer/countryInfo.txt')
    assert all

    sanitized = all.sanitize({query: 'Place Pey Berland Bât 4, Bordeaux (au fond à droite)'})[:query]
    assert_equal 'Place Pey Berland , Bordeaux ', sanitized
  end
end
