namespace :import do
  desc "Import neighborhood boundaries from GeoJSON file"
  task neighborhoods: :environment do
    require 'json'
    require 'rgeo-geojson'

    file_path = Rails.root.join('data', 'neighborhoods.geojson')
    puts "Importing neighborhoods from #{file_path}..."

    # Read data and parse file
    geojson_data = File.read(file_path)
    geojson = JSON.parse(geojson_data)

    # Set up factory for parsing GeoJSON
    factory = RGeo::Geographic.spherical_factory(srid: 4326)

    # Process each feature
    count = 0
    geojson['features'].each do |feature| 
      # Extract area name from properties
      name = feature['properties']['AREA_NAME'] || "Neighborhood #{count+1}"

      begin
        # Convert GeoJSON geometry to RGeo geometry
        geometry_data = feature['geometry']
        geometry = nil

        if geometry_data['type'] == 'Polygon'
          points = []
          geometry_data['coordinates'][0].each do |coord|
            points << factory.point(coord[0], coord[1])
          end

          ring = factory.linear_ring(points)
          geometry = factory.polygon(ring)
          # Create neighborhood record
          Neighborhood.create(name: name, geometry: geometry)
          count += 1

          puts "Created: #{name}"
        else
          puts "Skipping #{name}: geometry type #{geometry_data[type]} not supported"
        end
      rescue => e 
        puts "Error creating '#{name}': #{e.message}"
      end
    end

    puts "Successfully imported #{count} neighborhoods"
  end
end

