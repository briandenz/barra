require 'net/http'
require 'json'

class OsmService
  OVERPASS_API_URL = 'https://overpass-api.de/api/interpreter'

  def self.find_grocery_stores_within_bounds(bounds)

    Rails.logger.debug "Searching for store within bounds: #{bounds.inspect}"
    # Bounds format: [south, west, north, east]
    south, west, north, east = bounds

    #Overpass Query (OverpassQL)
    query = <<~QUERY
      [out:json];
      (
        node["shop"="supermarket"](#{south},#{west},#{north},#{east});
        node["shop"="convenience"](#{south},#{west},#{north},#{east});
        node["shop"="grocery"](#{south},#{west},#{north},#{east});
        way["shop"="supermarket"](#{south},#{west},#{north},#{east});
        way["shop"="convenience"](#{south},#{west},#{north},#{east});
        way["shop"="grocery"](#{south},#{west},#{north},#{east});
        relation["shop"="supermarket"](#{south},#{west},#{north},#{east});
        relation["shop"="convenience"](#{south},#{west},#{north},#{east});
        relation["shop"="grocery"](#{south},#{west},#{north},#{east});
      );
      out center body;
    QUERY

    Rails.logger.debug "Overpass query: #{query}"

    # Build request
    uri = URI(OVERPASS_API_URL)
    request = Net::HTTP::Post.new(uri)
    request.body = "data=#{query}"

    # Send request

    Rails.logger.debug "Sending request to Overpass API"

    response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
      http.request(request)
    end

    # Parse and return results
    if response.is_a?(Net::HTTPSuccess)
      Rails.logger.debug "Successful response from Overpass API"
      results = JSON.parse(response.body)
      Rails.logger.debug "Found #{results['elements']&.size || 0} elements in the response"
      process_osm_results(results)
    else
      Rails.logger.error "OSM API error: #{response.code} - #{response.message}"
      Rails.logger.error "Response body: #{response.body}"
      []
    end
  rescue => e 
    Rails.logger.error "Error fetching OSM data: #{e.message}"
    Rails.logger.error e.backtrack.join("\n")
    []
  end

  def self.process_osm_results(results)
    stores = []

    results['elements'].each do |element|
      # Get lat/lon from element (handles node, centers)
      if element['type'] == 'node'
        lat = element['lat']
        lon = element['lon']
      elsif element['center']
        lat = element['center']['lat']
        lon = element['center']['lon']
      else
        next # Skip if no location info
      end

      # Extract store info
      name = element['tags']['name'] || 'Unnamed store'

      # Determine store type
      type = case element['tags']['shop']
        when 'supermarket'
        'Supermarket'
        when 'convenience'
        'Convenience Store'
        else
        'Grocery Store'
      end

      # Build address components
      street = element['tags']['addr:street'] || ''
      housenumber = element['tags']['addr:housenumber'] || ''
      postcode = element['tags']['addr:postcode'] || ''
      city = element['tags']['addr:city'] || ''

      address = [
        [housenumber, street].reject(&:empty?).join(' '),
        city,
        postcode
    ].reject(&:empty?).join(', ')

      # Add to stores array
      store_data << {
        id: element['id'].to_s,
        name: name,
        type: type || 'Unknown type',
        address: address.empty? ? 'Address unknown' : address,
        latitude: lat.to_f,
        longitude: lon.to_f
      }

      stores << store_data
    end

    stores
  end
end



