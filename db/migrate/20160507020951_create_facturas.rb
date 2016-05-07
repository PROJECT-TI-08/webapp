class CreateFacturas < ActiveRecord::Migration
  def change
    create_table :facturas do |t|
      t.string :_id
      t.float :bruto
      t.float :iva
      t.float :total

      t.timestamps null: false
    end
  end
end
