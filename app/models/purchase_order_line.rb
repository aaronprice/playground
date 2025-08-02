class PurchaseOrderLine < ApplicationRecord
  belongs_to :purchase_order

  validates :sku, presence: true
end