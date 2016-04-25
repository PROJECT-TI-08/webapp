class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.datetime :created_date, null: false
      t.integer  :channel, null: false
      t.string   :provider, null: false
      t.string   :client, null: false
      t.string	 :sku, null: false
      t.integer  :qty, null: false
      t.integer  :sent_qty, null: false
      t.integer  :unit_price, null: false
      t.datetime :sent_date, null: false
      t.text     :delivered_dates, array: true, default: []
      t.integer  :status, null: false
  	  t.text     :rejection_reason, null: true
  	  t.text     :cancelation_reason, null: true
  	  t.text     :notes, null:false
  	  t.string   :invoice, null:false

      t.timestamps null: false
    end
  end
end
