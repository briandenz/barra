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

  def stores
    neighborhood_ids = params[:ids].split(',')
    neighborhoods = Neighborhood.where(id: neighborhood_ids)

    #Mock data
    stores = [
      { id: 1, name: "Whole Foods Market", address: "123 Main St", neighborhood_name: "Downtown" },
      { id: 2, name: "Trader Joe's", address: "456 Oak Ave", neighborhood_name: "Uptown" },
      { id: 3, name: "Safeway", address: "789 Pine St", neighborhood_name: "Downtown" }
    ]

    render json: { stores: stores } 
  end
end
