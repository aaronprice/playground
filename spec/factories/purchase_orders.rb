FactoryBot.define do
  factory :purchase_order do
    external_po_id { "PO-#{SecureRandom.hex(4).upcase}" }
    customer
    requested_ship_date { Date.current + 1.week }
    currency { "USD" }
    status { "draft" }
  end
end 