class FetchSkuPriceJob < ApplicationJob
  queue_as :default
  # retry_on ActiveRecord::RecordNotFound, wait: :exponentially_longer, attempts: 3

  def perform(purchase_order_line_id)
    PurchaseOrders::HydrateSkuPrices.("purchase_order_line_id" => purchase_order_line_id)
  end
end