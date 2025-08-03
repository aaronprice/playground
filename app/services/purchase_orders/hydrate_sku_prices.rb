# frozen_string_literal: true

require "httparty"

class PurchaseOrders::HydrateSkuPrices

  # == Constants ============================================================

  # == Attributes ===========================================================

  attr_reader :purchase_order_line

  # == Extensions ===========================================================

  include Serviceable

  # == Relationships ========================================================

  # == Aliases ==============================================================

  # == Validations ==========================================================

  validate :validate_purchase_order_line

  # == Callbacks ============================================================

  # == Scopes ===============================================================

  # == Class Methods ========================================================

  # == Instance Methods =====================================================

  private

  def schema
    Dry::Schema.Params do
      required(:purchase_order_line_id).filled(:integer)
    end
  end

  def validate_purchase_order_line
    @purchase_order_line = PurchaseOrderLine.find_by(id: @params["purchase_order_line_id"])
    errors.add(:purchase_order_line_id, "not found") unless @purchase_order_line
  end

  def perform
    fetch_prices_for_skus
  end

  def fetch_prices_for_skus
    response = HTTParty.get("https://web.playground.orb.local/skus/#{@purchase_order_line.sku}?currency=#{@purchase_order_line.currency}", {
      timeout: 30,
      headers: {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    })

    if response.success?
      data = ::JSON.parse(response.body)

      @purchase_order_line.update(
        unit_price: BigDecimal(data["price"]),
        total_price: (BigDecimal(data["price"]) * @purchase_order_line.quantity).round(3)
      )
    else
      handle_error_response(response)
    end
  rescue StandardError => e
    handle_exception(e)
  end

  def handle_error_response(response)
    error_message = "HTTP #{response.code}: #{response.message}"
    Rails.logger.error("Failed to fetch price for SKU #{@purchase_order_line.sku}: #{error_message}")
  end

  def handle_exception(exception)
    error_message = "Exception while fetching price for SKU #{@purchase_order_line.sku}: #{exception.message}"
    Rails.logger.error(error_message)
    Rails.logger.error(exception.backtrace.join("\n"))
  end
end