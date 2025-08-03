FactoryBot.define do
  factory :purchase_order_line do
    purchase_order
    sku { "SKU-#{SecureRandom.hex(4).upcase}" }
    quantity { rand(1..10) }
    currency { "USD" }
  end
end 