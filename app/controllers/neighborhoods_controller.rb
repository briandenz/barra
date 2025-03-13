class NeighborhoodsController < ApplicationController
  def index
    @neighborhoods = Neighborhood.all

    respond_to do |format|
      format.html
      format.json do
        render json: {
          type: "FeatureCollection",
          features: @neighborhoods.map { |n|
            {
              type: "Feature",
              properties: {
                id: n.id,
                name: n.name
              },
              geometry: RGeo::GeoJSON.encode(n.geometry) 
            }
          }
        }
      end
    end
  end
end
