class CreateFacturas < ActiveRecord::Migration
  def change
    create_table :facturas do |t|
      t.string :_id
      t.float :bruto
      t.float :iva
      t.float :total
      t.string :idtrx
      t.belongs_to :order, index: true, foreign_key: true
      t.timestamps null: false
    end
  end
end
