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
    neighborhood_ids = params[:ids].to_s.split(',')

    if neighborhood_ids.empty?
      return render json: { stores: [] }
    end
    begin
      #Collect grocery stores from all selected neighborhoods
      all_stores = []

      Neighborhood.where(id: neighborhood_ids).each do |neighborhood|
        neighborhood_stores = neighborhood.grocery_stores

        if neighborhood_stores.is_a?(Array)
          neighborhood_stores.each do |store| 
            store[:neighborhood_name] = neighborhood.name
          end

          all_stores.concat(neighborhood_stores)
        end
      end

      unique_stores = all_stores.uniq { |store| store[:id] }

      render json: { stores: unique_stores } 
    rescue => e 
      Rails.logger.error "Error in stores action: #{e.message}"
      render json: { error: "Error fetching stores", stores: [] }
    end
  end
end

