class Customer < ApplicationRecord
  has_many :purchase_orders, dependent: :destroy

  validates :external_customer_ref, presence: true
end