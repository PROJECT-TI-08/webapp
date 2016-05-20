class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.string   :_id, null: false
      t.string   :canal, null: false
      t.string   :proveedor, null: false
      t.string   :cliente, null: false
      t.integer	 :sku, null: false
      t.integer  :cantidad, null: false
      t.integer  :cantidadDespachada, null: false
      t.integer  :precioUnitario, null: false
      t.datetime :fechaEntrega, null: false
      t.datetime :fechaDespachos, array: true, default: []
      t.string   :estado, null: false
      t.integer  :tipo, default: 1

      t.timestamps null: false
    end
  end
end
