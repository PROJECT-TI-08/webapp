class CreateStores < ActiveRecord::Migration
  def change
    create_table :stores do |t|
      t.string  :_id
      t.boolean :pulmon
      t.boolean :despacho
      t.boolean :recepcion
      t.integer :totalSpace
      t.integer :usedSpace

      t.timestamps null: false
    end
  end
end
