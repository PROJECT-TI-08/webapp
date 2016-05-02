class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string  :sku
      t.string  :nombre
      t.string  :unidades
      t.float   :costo_produccion_unitario
      t.float   :lote_produccion
      t.float   :tiempo_medio_produccion
      t.float   :precio_unitario
      t.string  :tipo
      t.integer :stock_minimo
      t.timestamps null: false
    end
  end
end
