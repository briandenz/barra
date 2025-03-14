class Neighborhood < ApplicationRecord
  def bounding_box
    # Get bounding box of geometry
    box = RGeo::Cartesian::BoundingBox.create_from_geometry(geometry)

    # Return [south, west, north, east] format for Overpass API
    [box.min_y, box.min_x, box.max_y, box.max_x]
  end

  def grocery_stores
    #Cache for 24hr
    Rails.cache.fetch("neighborhood_#{id}_grocery_stores", expires_in: 24.hour) do 
      OsmService.find_grocery_stores_within_bounds(bounding_box) 
    end
  rescue => e 
    Rails.logger.error "Error fetching grocery stores for neighborhood #{id}: #{e.message}"
    []
  end
end
