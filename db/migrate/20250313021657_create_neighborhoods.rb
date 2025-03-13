class CreateNeighborhoods < ActiveRecord::Migration[8.0]
  def change

    # Enable PostGIS extension if not enabled in config/database.yml
    enable_extension 'postgis' unless extension_enabled?('postgis')

    create_table :neighborhoods do |t|
      t.string :name
      t.geometry :geometry, srid: 4326 #WGS84 
      t.timestamps
    end
    add_index :neighborhoods, :geometry, using: :gist
  end
end
