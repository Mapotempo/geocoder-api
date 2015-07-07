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
require 'grape'
require 'grape-swagger'
require 'grape-entity'

require './api/v01/unitary'
require './api/v01/bulk'

module Api
  class Root < Grape::API

    before do
      if !::AddokWrapper::config[:api_keys].include?(params[:api_key])
        error!('401 Unauthorized', 401)
      end
    end

    mount V01::Unitary
    mount V01::Bulk
    documentation_class = add_swagger_documentation hide_documentation_path: true, info: {
      title: ::AddokWrapper::config[:product_title],
      description: 'API access require an api_key.',
      contact: ::AddokWrapper::config[:product_contact]
    }
  end
end
