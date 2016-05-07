class AddOrderRefToFacturas < ActiveRecord::Migration
  def change
    add_reference :facturas, :order, index: true, foreign_key: true
  end
end
