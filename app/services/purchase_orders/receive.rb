# frozen_string_literal: true

class PurchaseOrders::Receive

  # == Constants ============================================================

  # == Attributes ===========================================================

  attr_reader :customer, :purchase_order

  # == Extensions ===========================================================

  include Serviceable

  # == Relationships ========================================================

  # == Aliases ==============================================================

  # == Validations ==========================================================

  validate :validate_lines

  # == Callbacks ============================================================

  # == Scopes ===============================================================

  # == Class Methods ========================================================

  # == Instance Methods =====================================================

  private

  # This is necessary because of a bug in Dry::Schema
  # that doesn't properly validate a mininmum amount of
  # objects in an array. Without it, if "lines" was
  # empty in the params, it would result in a 500 error.
  def validate_lines
    if @params["lines"].is_a?(Array) && @params["lines"].empty?
      errors.add(:lines, "cannot be empty")
    end
  end

  def schema
    # {
    #   "external_po_id": "PO-12345",
    #   "customer": {
    #     "external_customer_ref": "CUST-998",
    #     "name": "Acme Inc",
    #     "email": "buy@acme.example",
    #     "shipping_address": { "line1":"1 Main", "city":"NYC", "state":"NY", "postal_code":"10001", "country":"US" }
    #   },
    #   "lines": [
    #     { "sku":"SKU-001", "quantity":2 },
    #     { "sku":"SKU-002", "quantity":1 }
    #   ],
    #   "requested_ship_date": "2025-08-05",
    #   "currency": "USD"
    # }
    Dry::Schema.Params do
      required(:external_po_id).filled(:string)
      required(:customer).hash do
        required(:external_customer_ref).filled(:string)
        required(:name).filled(:string)
        required(:email).filled(:string, format?: /@/)
        optional(:shipping_address).hash do
          required(:line1).filled(:string)
          optional(:line2).maybe(:string)
          required(:city).filled(:string)
          required(:state).filled(:string)
          required(:postal_code).filled(:string)
          required(:country).filled(:string, format?: /\A(?:US|CA)\z/)
        end
      end
      required(:lines).array(:hash) do
        required(:sku).filled(:string)
        required(:quantity).filled(:integer)
      end
      optional(:requested_ship_date).filled(:string, format?: /\A(?!0000)([0-9]{4})-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])\z/)
      required(:currency).filled(:string, format?: /\A(?:USD|CAD)\z/)
    end
  end

  def perform
    upsert_customer
    upsert_purchase_order
    upsert_purchase_order_lines
    fetch_prices_for_lines
  end

  def upsert_customer
    @customer = Customer.create_or_find_by!(external_customer_ref: @params["customer"]["external_customer_ref"]) do |customer|
      customer.name = @params.dig("customer", "name")
      customer.email = @params.dig("customer", "email")
      customer.line1 = @params.dig("customer", "shipping_address", "line1")
      customer.line2 = @params.dig("customer", "shipping_address", "line2")
      customer.city = @params.dig("customer", "shipping_address", "city")
      customer.state = @params.dig("customer", "shipping_address", "state")
      customer.postal_code = @params.dig("customer", "shipping_address", "postal_code")
      customer.country = @params.dig("customer", "shipping_address", "country")
    end

    @value["customer"] ||= {}
    @value["customer"]["id"] = @customer.id
    @value["customer"]["external_customer_ref"] = @customer.external_customer_ref
    @value["customer"]["name"] = @customer.name
    @value["customer"]["email"] = @customer.email
    @value["customer"]["line1"] = @customer.line1
    @value["customer"]["line2"] = @customer.line2
    @value["customer"]["city"] = @customer.city
    @value["customer"]["state"] = @customer.state
    @value["customer"]["postal_code"] = @customer.postal_code
    @value["customer"]["country"] = @customer.country
  end

  def upsert_purchase_order
    @purchase_order = PurchaseOrder.create_or_find_by!(external_po_id: @params["external_po_id"]) do |purchase_order|
      purchase_order.customer = @customer
      purchase_order.requested_ship_date = @params["requested_ship_date"]
      purchase_order.currency = @params["currency"]
    end

    @value["purchase_order"] ||= {}
    @value["purchase_order"]["id"] = @purchase_order.id
    @value["purchase_order"]["external_po_id"] = @purchase_order.external_po_id
    @value["purchase_order"]["currency"] = @purchase_order.currency
  end

  def upsert_purchase_order_lines
    @params["lines"].each do |line|
      @purchase_order.purchase_order_lines.create_or_find_by!(sku: line["sku"]) do |purchase_order_line|
        purchase_order_line.quantity = line["quantity"]
        purchase_order_line.currency = @params["currency"]
      end
    end

    @value["purchase_order"] ||= {}
    @value["purchase_order"]["lines_count"] = @purchase_order.purchase_order_lines.count
  end

  def fetch_prices_for_lines
    @purchase_order.purchase_order_lines.where(unit_price: nil).find_each do |line|
      FetchSkuPriceJob.perform_later(line.id)
    end
  end
end