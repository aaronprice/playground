require 'rails_helper'

RSpec.describe SkusController, type: :controller do
  describe 'GET #show' do
    context 'with a valid SKU ID' do
      let(:sku_id) { 'SKU-12345' }

      it 'returns a successful response' do
        get :show, params: { id: sku_id }

        expect(response).to have_http_status(:ok)
      end

      it 'returns the correct JSON structure' do
        get :show, params: { id: sku_id }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key('sku')
        expect(parsed_response).to have_key('currency')
        expect(parsed_response).to have_key('price')
      end

      it 'returns the SKU ID in the response' do
        get :show, params: { id: sku_id }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['sku']).to eq(sku_id)
      end

      it 'returns USD as the default currency when no currency parameter is provided' do
        get :show, params: { id: sku_id }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['currency']).to eq('USD')
      end

      it 'returns a price calculated from MD5 hash' do
        get :show, params: { id: sku_id }

        parsed_response = JSON.parse(response.body)
        price = parsed_response['price']

        # Verify it's a valid decimal number
        expect(price).to match(/^\d+\.\d{2}$/)
        expect(price.to_f).to be > 0
      end

      it 'calculates consistent price for the same SKU ID' do
        get :show, params: { id: sku_id }
        first_response = JSON.parse(response.body)

        get :show, params: { id: sku_id }
        second_response = JSON.parse(response.body)

        expect(first_response['price']).to eq(second_response['price'])
      end

      it 'calculates different prices for different SKU IDs' do
        get :show, params: { id: 'SKU-12345' }
        first_price = JSON.parse(response.body)['price']

        get :show, params: { id: 'SKU-67890' }
        second_price = JSON.parse(response.body)['price']

        expect(first_price).not_to eq(second_price)
      end
    end

    context 'with different SKU ID formats' do
      it 'handles alphanumeric SKU IDs' do
        get :show, params: { id: 'ABC123' }

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['sku']).to eq('ABC123')
      end

      it 'handles SKU IDs with special characters' do
        get :show, params: { id: 'SKU-123_456' }

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['sku']).to eq('SKU-123_456')
      end

      it 'handles very long SKU IDs' do
        long_sku = 'A' * 100
        get :show, params: { id: long_sku }

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['sku']).to eq(long_sku)
      end

      it 'handles single character SKU IDs' do
        get :show, params: { id: 'A' }

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['sku']).to eq('A')
      end
    end

    context 'with edge cases' do
      it 'handles empty SKU ID' do
        get :show, params: { id: '' }

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['sku']).to eq('')
        expect(parsed_response['price']).to match(/^\d+\.\d{2}$/)
      end

      it 'handles numeric SKU IDs' do
        get :show, params: { id: '12345' }

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['sku']).to eq('12345')
      end

      it 'handles SKU IDs with spaces' do
        get :show, params: { id: 'SKU 123' }

        expect(response).to have_http_status(:ok)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response['sku']).to eq('SKU 123')
      end
    end

    context 'response format validation' do
      let(:sku_id) { 'TEST-SKU' }

      it 'returns JSON content type' do
        get :show, params: { id: sku_id }

        expect(response.content_type).to include('application/json')
      end

      it 'returns a valid JSON response' do
        get :show, params: { id: sku_id }

        expect { JSON.parse(response.body) }.not_to raise_error
      end

      it 'has exactly three keys in the response' do
        get :show, params: { id: sku_id }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response.keys).to match_array(['sku', 'currency', 'price'])
      end

      it 'returns price as a string with exactly two decimal places' do
        get :show, params: { id: sku_id }

        parsed_response = JSON.parse(response.body)
        price = parsed_response['price']

        expect(price).to be_a(String)
        expect(price).to match(/^\d+\.\d{2}$/)
      end
    end

    context 'currency parameter handling' do
      let(:sku_id) { 'SKU-12345' }

      it 'returns the provided currency when currency parameter is passed' do
        get :show, params: { id: sku_id, currency: 'EUR' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['currency']).to eq('EUR')
      end

      it 'returns the provided currency for different currency codes' do
        get :show, params: { id: sku_id, currency: 'CAD' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['currency']).to eq('CAD')
      end

      it 'handles lowercase currency codes' do
        get :show, params: { id: sku_id, currency: 'gbp' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['currency']).to eq('gbp')
      end

      it 'handles currency codes with special characters' do
        get :show, params: { id: sku_id, currency: 'BTC' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['currency']).to eq('BTC')
      end

      it 'handles empty currency parameter' do
        get :show, params: { id: sku_id, currency: '' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['currency']).to eq('')
      end

      it 'handles nil currency parameter' do
        get :show, params: { id: sku_id, currency: nil }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['currency']).to eq('')
      end

      it 'defaults to USD when currency parameter is not provided' do
        get :show, params: { id: sku_id }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['currency']).to eq('USD')
      end

      it 'maintains other response fields when currency is provided' do
        get :show, params: { id: sku_id, currency: 'JPY' }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['sku']).to eq(sku_id)
        expect(parsed_response['currency']).to eq('JPY')
        expect(parsed_response).to have_key('price')
        expect(parsed_response['price']).to match(/^\d+\.\d{2}$/)
      end
    end

    context 'price calculation verification' do
      it 'calculates price based on MD5 hash of SKU ID' do
        sku_id = 'TEST-SKU-123'
        expected_hash = Digest::MD5.hexdigest(sku_id)
        expected_price = sprintf("%.2f", (expected_hash[0..3].to_i(16) / 100.0))

        get :show, params: { id: sku_id }

        parsed_response = JSON.parse(response.body)
        expect(parsed_response['price']).to eq(expected_price)
      end

      it 'produces reasonable price ranges' do
        prices = []

        ['A', 'B', 'C', 'D', 'E'].each do |sku_id|
          get :show, params: { id: sku_id }
          prices << JSON.parse(response.body)['price'].to_f
        end

        # All prices should be positive and reasonable
        prices.each do |price|
          expect(price).to be > 0
          expect(price).to be < 1000 # Reasonable upper bound
        end
      end
    end
  end
end