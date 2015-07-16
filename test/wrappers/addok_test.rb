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
require './test/test_helper'

require './wrappers/addok'

class Wrappers::AddokTest < Minitest::Test

  def test_geocodes_from_full_text
    rg = AddokWrapper::ADDOK_FRA
    result = rg.geocodes([{query: '50 Bv de la Plage, Arcachon'}])
    assert 0 < result.size
    g = result[0][:properties][:geocoding]
    assert_equal 'Arcachon', g[:city]
  end

  def test_geocodes_from_part
    rg = AddokWrapper::ADDOK_FRA
    result = rg.geocodes([{housenumber: '50', street: 'Bv de la Plage', city: 'Arcachon'}])
    assert 0 < result.size
    g = result[0][:properties][:geocoding]
    assert_equal 'Arcachon', g[:city]
  end

  def test_reverses
    rg = AddokWrapper::ADDOK_FRA
    result = rg.reverses([{lat: 47.09305, lng: 5.48827}])
    assert_equal 1, result.size
    g = result[0][:properties][:geocoding]
    assert_equal 'Dole', g[:city]
  end
end
