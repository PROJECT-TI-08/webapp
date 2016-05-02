class CreateFormulas < ActiveRecord::Migration
  def change
    create_table :formulas , :id => false do |t|
      t.string :sku_parent
      t.string :sku_child
      t.integer :requerimiento
      t.float :precio

      t.timestamps null: false
    end

    add_index :formulas, [:sku_parent, :sku_child], :unique => true
  end
end
