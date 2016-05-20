class CreateOrderFtps < ActiveRecord::Migration
  def change
    create_table :order_ftps do |t|
      t.string :file_name	
      t.string :order_id
      t.integer :status

      t.timestamps null: false
    end
  end
end
