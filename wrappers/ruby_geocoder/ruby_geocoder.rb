module Wrappers
  class RubyGeocoder < Wrapper
    def initialize(cache, boundary = nil)
      super(cache, boundary)
    end

    def reverse(params)
      make_request query: [params[:lat], params[:lng]]
    end

    def geocode(params, limit = 10)
      make_request params, limit: limit
    end

    def make_request(params, options = {})
      key_params = build_key_params(params, options)
      cached_data = read_cache(key_params)

      return cached_data unless cached_data.nil?

      setup_geocoder

      maybe_streets = maybe_streets?(params)
      # query can be a single query string or an array if maybe street
      query = build_request_query(params, maybe_streets)

      # return an array with query as first index and geocode result as 2nd index
      query, response = process_query(query, options, maybe_streets)

      features = response.collect { |response_data| build_features(query, response_data.data, options) }

      r = @header.dup
      r[:geocoding][:query] = query
      r[:features] = features

      write_cache(key_params, r)
      r
    end

    protected

    def maybe_streets?(params)
      !params.key? :query
    end

    def build_request_query(params, maybe_streets)
      return params unless maybe_streets
      p = params.dup
      gen_streets(params).map do |street|
        p[:street] = street
        p
      end
    end

    def setup_geocoder
      raise NotImplementedError
    end

    def read_cache(_key_params)
      raise NotImplementedError
    end

    def write_cache(_key_params, _features)
      raise NotImplementedError
    end

    def max_by(_result)
      raise NotImplementedError
    end

    private

    def reverse_query?(query_object)
      if query_object[:query].is_a?(Array)
        query_object[:query]
      else
        flatten_query(query_object)
      end
    end

    def process_query(query_object, options, maybe_streets)
      # if maybe_street, generate array of queries to be send,
      # then sort best result
      if maybe_streets
        results = query_object.map do |query_params|
          query = flatten_query(query_params)
          [query, Geocoder.search(query, options)]
        end
        results.max_by { |r| max_by(r[1]) } || [nil, []] # sort maybe_street
      else
        query = reverse_query?(query_object)
        [query, Geocoder.search(query, options)]
      end
    end

    def build_key_params(params, options)
      {
        limit: options[:limit],
      }.merge(params).reject { |k, _| k == 'api_key' }
    end
  end
end
