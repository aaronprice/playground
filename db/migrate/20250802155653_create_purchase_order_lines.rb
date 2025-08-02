class CreatePurchaseOrderLines < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_order_lines do |t|
      t.references :purchase_order, null: false, foreign_key: true
      t.string :sku, null: false
      t.integer :quantity
      t.decimal :unit_price, precision: 21, scale: 3
      t.decimal :total_price, precision: 21, scale: 3
      t.string :currency, null: false, default: "USD"

      t.timestamps
    end
  end
end
