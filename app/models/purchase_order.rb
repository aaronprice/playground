class PurchaseOrder < ApplicationRecord
  belongs_to :customer

  has_many :purchase_order_lines, dependent: :destroy

  validates :external_po_id, presence: true
end