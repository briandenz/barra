class CreateLandlords < ActiveRecord::Migration[8.0]
  def change
    create_table :landlords do |t|
      t.string :name
      t.string :company_name

      t.timestamps
    end
  end
end
