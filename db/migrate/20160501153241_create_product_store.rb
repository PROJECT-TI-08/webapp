class CreateProductStore < ActiveRecord::Migration
  def change
    create_table :product_stores, :id => false do |t|
      t.belongs_to :product, index: true, foreign_key: true
      t.belongs_to :store, index: true, foreign_key: true
      t.integer    :qty
      t.timestamps null: false
    end

	add_index :product_stores, [:product_id, :store_id], :unique => true

  end
end
