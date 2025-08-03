FactoryBot.define do
  factory :customer do
    external_customer_ref { "CUST-#{SecureRandom.hex(4).upcase}" }
    name { "Test Customer" }
    email { "test@example.com" }
    line1 { "123 Test St" }
    city { "Test City" }
    state { "TS" }
    postal_code { "12345" }
    country { "US" }
  end
end 