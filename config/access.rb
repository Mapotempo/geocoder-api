# Copyright © Mapotempo, 2019
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
  @access_by_api_key = {
    # params_limit and quota overload values from profile
    'demo' => { profile: :standard },
    'bulk_limit' => { profile: :standard, params_limit: { locations: 2 }, quotas: [{ operation: :complete, daily: 1 }, { monthly: 2 }] },
    'bulk_nil_quotas' => { profile: :quotas, params_limit: { locations: 2 }, quotas: [{ operation: :complete, daily: nil }] },
    'expired' => { profile: :standard, expire_at: '2000-01-01' }
  }
end
