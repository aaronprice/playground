class CreatePurchaseOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :purchase_orders do |t|
      t.string :external_po_id, null: false
      t.references :customer, null: false, foreign_key: true
      t.date :requested_ship_date
      t.string :currency, null: false, default: "USD"
      t.string :status, null: false, default: "draft"

      t.timestamps
    end
  end
end
