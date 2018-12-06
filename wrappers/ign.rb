require 'net/http'
require 'rexml/document'
require 'json'
include REXML

module Wrappers
  class Ign < Wrapper

    MATCHTYPE = { 'street number' => 'house', 'street enhanced' => 'street' }.freeze

    def initialize(api_key, cache, boundary = nil)
      super(cache, boundary)

      url = URI.parse("http://wxs.ign.fr/#{api_key}/geoportail/ols")
      @http = Net::HTTP.new(url.host)

      @request = Net::HTTP::Post.new(url.path)
      @request['Content-Type'] = 'application/xml'
      @request['User-agent'] = 'test'
    end

    def geocode(data, limit = 10)
      @request.body = "<?xml version='1.0' encoding='UTF-8'?>
      <XLS
          xmlns:xls='http://www.opengis.net/xls'
          xmlns:gml='http://www.opengis.net/gml'
          xmlns='http://www.opengis.net/xls'
          xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance'
          version='1.2'
          xsi:schemaLocation='http://www.opengis.net/xls http://schemas.opengis.net/ols/1.2/olsAll.xsd'>
        <RequestHeader/>
        <Request requestID='1' version='1.2' methodName='LocationUtilityService'>
         <GeocodeRequest returnFreeForm='false'>
           <Address countryCode='StreetAddress'>
             <StreetAddress>
               <Street>#{data['housenumber'].to_s + ' ' + data['street'].to_s}</Street>
             </StreetAddress>
             <Place type='Municipality'>#{data['city'].to_s}</Place>
             <PostalCode>#{data['postcode'].to_s}</PostalCode>
           </Address>
         </GeocodeRequest>
        </Request>
      </XLS>"

      response = @http.request(@request)
      if response.nil?
        raise 'An error has occured'
      elsif response.code == '200'
        root = Document.new(response.body).root

        geocodedAddress = root.elements['Response'].elements['GeocodeResponse'].elements['GeocodeResponseList'].elements['GeocodedAddress']
        pos = geocodedAddress.elements['gml:Point'].elements['gml:pos'].text
        pos = pos.split(' ')

        geocodeMatchCode = geocodedAddress.elements['GeocodeMatchCode']
        type = geocodeMatchCode.attribute('matchType').value.downcase
        MATCHTYPE.each { |k, v| type.gsub!(k, v) }
        accuracy = Float(geocodeMatchCode.attribute('accuracy').value)

        address = geocodedAddress.elements['Address']
        street = address.elements['StreetAddress'].elements['Street'].text
        city = address.elements['Place@type=\'Commune\']'].text
        postcode = address.elements['PostalCode'].text
        housenumber = address.elements['StreetAddress'].elements['Building'] ? address.elements['StreetAddress'].elements['Building'].attribute('number').value : nil
        label = "#{housenumber} #{street} #{city} #{postcode}".strip
        f = {
          features: [
            properties: {
              geocoding: {
                version: version(),
                score: accuracy,
                type: type,
                label: label,
                name: nil,
                housenumber: housenumber,
                street: street,
                postcode: postcode,
                city: city,
                district: nil,
                county: nil,
                state: nil,
                country: 'France',
              }.delete_if{ |k, v| v.nil? || v == '' }
            },
            type: 'Feature',
            geometry: {
              coordinates: [
                pos[1],
                pos[0]
              ],
              type: 'Point'
            }
          ]
        }
        f
      else
        "Error : #{response.body}"
      end
    end

    protected

    def version(query = nil)
      "#{super} - ign"
    end
  end
end
