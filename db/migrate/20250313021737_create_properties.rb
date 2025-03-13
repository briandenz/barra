class CreateProperties < ActiveRecord::Migration[8.0]
  def change
    create_table :properties do |t|
      t.string :address
      t.float :latitude
      t.float :longitude
      t.string :neighborhood
      t.string :references

      t.timestamps
    end
  end
end
