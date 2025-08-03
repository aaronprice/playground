require 'rails_helper'

RSpec.describe PurchaseOrders::HydrateSkuPrices, type: :service do
  let(:purchase_order_line) { create(:purchase_order_line, sku: "SKU-123", quantity: 5, currency: "USD") }

  describe '#call' do
    context 'when the service succeeds' do
      before do
        stub_request(:get, "https://web.playground.orb.local/skus/SKU-123?currency=USD")
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: { price: 25.50 }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'updates the purchase order line with fetched prices' do
        result = described_class.call("purchase_order_line_id" => purchase_order_line.id)

        expect(result).to be_success
        expect(purchase_order_line.reload.unit_price).to eq(25.50)
        expect(purchase_order_line.reload.total_price).to eq(127.50) # 25.50 * 5
      end

      it 'returns success result' do
        result = described_class.call("purchase_order_line_id" => purchase_order_line.id)

        expect(result.success?).to be true
        expect(result.value).to eq({})
        expect(result.errors).to eq({})
      end
    end

    context 'when the service fails with HTTP error' do
      before do
        stub_request(:get, "https://web.playground.orb.local/skus/SKU-123?currency=USD")
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
            }
          )
          .to_return(status: 404, body: "Not Found")
      end

      it 'handles the error gracefully' do
        result = described_class.call("purchase_order_line_id" => purchase_order_line.id)

        expect(result).to be_success # Service doesn't fail, just logs the error
        expect(purchase_order_line.reload.unit_price).to be_nil
        expect(purchase_order_line.reload.total_price).to be_nil
      end
    end

    context 'when the service fails with network error' do
      before do
        stub_request(:get, "https://web.playground.orb.local/skus/SKU-123?currency=USD")
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
            }
          )
          .to_raise(Net::ReadTimeout.new("timeout"))
      end

      it 'handles the exception gracefully' do
        result = described_class.call("purchase_order_line_id" => purchase_order_line.id)

        expect(result).to be_success # Service doesn't fail, just logs the error
        expect(purchase_order_line.reload.unit_price).to be_nil
        expect(purchase_order_line.reload.total_price).to be_nil
      end
    end

    context 'when purchase order line is not found' do
      it 'returns validation error' do
        result = described_class.call("purchase_order_line_id" => 99999)

        expect(result).not_to be_success
        expect(result.errors["purchase_order_line_id"]).to include("not found")
      end
    end

    context 'with different currencies' do
      let(:purchase_order_line_eur) { create(:purchase_order_line, sku: "SKU-EUR", quantity: 3, currency: "EUR") }

      before do
        stub_request(:get, "https://web.playground.orb.local/skus/SKU-EUR?currency=EUR")
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: { price: 30.00 }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fetches prices with the correct currency parameter' do
        result = described_class.call("purchase_order_line_id" => purchase_order_line_eur.id)

        expect(result).to be_success
        expect(purchase_order_line_eur.reload.unit_price).to eq(30.00)
        expect(purchase_order_line_eur.reload.total_price).to eq(90.00) # 30.00 * 3
      end
    end

    context 'with different SKUs' do
      let(:purchase_order_line_different_sku) { create(:purchase_order_line, sku: "SKU-456", quantity: 2, currency: "USD") }

      before do
        stub_request(:get, "https://web.playground.orb.local/skus/SKU-456?currency=USD")
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: { price: 15.75 }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'fetches prices for different SKUs' do
        result = described_class.call("purchase_order_line_id" => purchase_order_line_different_sku.id)

        expect(result).to be_success
        expect(purchase_order_line_different_sku.reload.unit_price).to eq(15.75)
        expect(purchase_order_line_different_sku.reload.total_price).to eq(31.50) # 15.75 * 2
      end
    end

    context 'with decimal prices' do
      before do
        stub_request(:get, "https://web.playground.orb.local/skus/SKU-123?currency=USD")
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: { price: 12.99 }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'handles decimal prices correctly' do
        result = described_class.call("purchase_order_line_id" => purchase_order_line.id)

        expect(result).to be_success
        expect(purchase_order_line.reload.unit_price).to eq(12.99)
        expect(purchase_order_line.reload.total_price).to eq(64.95) # 12.99 * 5
      end
    end

    context 'with zero quantity' do
      let(:purchase_order_line_zero_qty) { create(:purchase_order_line, sku: "SKU-ZERO", quantity: 0, currency: "USD") }

      before do
        stub_request(:get, "https://web.playground.orb.local/skus/SKU-ZERO?currency=USD")
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: { price: 10.00 }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'calculates total price correctly with zero quantity' do
        result = described_class.call("purchase_order_line_id" => purchase_order_line_zero_qty.id)

        expect(result).to be_success
        expect(purchase_order_line_zero_qty.reload.unit_price).to eq(10.00)
        expect(purchase_order_line_zero_qty.reload.total_price).to eq(0.00) # 10.00 * 0
      end
    end

    context 'with invalid JSON response' do
      before do
        stub_request(:get, "https://web.playground.orb.local/skus/SKU-123?currency=USD")
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: "invalid json",
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'handles invalid JSON gracefully' do
        result = described_class.call("purchase_order_line_id" => purchase_order_line.id)

        expect(result).to be_success # Service doesn't fail, just logs the error
        expect(purchase_order_line.reload.unit_price).to be_nil
        expect(purchase_order_line.reload.total_price).to be_nil
      end
    end

    context 'with missing price in response' do
      before do
        stub_request(:get, "https://web.playground.orb.local/skus/SKU-123?currency=USD")
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
            }
          )
          .to_return(
            status: 200,
            body: { sku: "SKU-123" }.to_json,
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      it 'handles missing price field gracefully' do
        result = described_class.call("purchase_order_line_id" => purchase_order_line.id)

        expect(result).to be_success # Service doesn't fail, just logs the error
        expect(purchase_order_line.reload.unit_price).to be_nil
        expect(purchase_order_line.reload.total_price).to be_nil
      end
    end

    context 'with 500 server error' do
      before do
        stub_request(:get, "https://web.playground.orb.local/skus/SKU-123?currency=USD")
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
            }
          )
          .to_return(status: 500, body: "Internal Server Error")
      end

      it 'handles server error gracefully' do
        result = described_class.call("purchase_order_line_id" => purchase_order_line.id)

        expect(result).to be_success # Service doesn't fail, just logs the error
        expect(purchase_order_line.reload.unit_price).to be_nil
        expect(purchase_order_line.reload.total_price).to be_nil
      end
    end

    context 'with timeout error' do
      before do
        stub_request(:get, "https://web.playground.orb.local/skus/SKU-123?currency=USD")
          .with(
            headers: {
              'Accept' => 'application/json',
              'Content-Type' => 'application/json'
            }
          )
          .to_timeout
      end

      it 'handles timeout error gracefully' do
        result = described_class.call("purchase_order_line_id" => purchase_order_line.id)

        expect(result).to be_success # Service doesn't fail, just logs the error
        expect(purchase_order_line.reload.unit_price).to be_nil
        expect(purchase_order_line.reload.total_price).to be_nil
      end
    end
  end
end