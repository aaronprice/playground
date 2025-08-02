require 'rails_helper'

RSpec.describe PurchaseOrders::Receive do
  let(:valid_params) do
    {
      external_po_id: "PO-12345",
      name: "Acme Inc",
      email: "buy@acme.example",
      shipping_address: {
        line1: "1 Main St",
        line2: "Suite 100",
        city: "New York",
        postal_code: "10001",
        country: "US"
      },
      lines: [
        { sku: "SKU-001", quantity: 2 },
        { sku: "SKU-002", quantity: 1 }
      ],
      requested_ship_date: "2025-08-05",
      currency: "USD"
    }
  end

  describe '.call' do
    it 'creates a new instance and calls it' do
      service = instance_double(described_class)
      allow(described_class).to receive(:new).with(valid_params).and_return(service)
      allow(service).to receive(:call).and_return(Dry::Monads::Success(true))

      result = described_class.call(valid_params)

      expect(result).to be_success
      expect(described_class).to have_received(:new).with(valid_params)
      expect(service).to have_received(:call)
    end
  end

  describe '#initialize' do
    it 'sets the params attribute' do
      service = described_class.new(valid_params)
      expect(service.params).to eq(valid_params)
    end
  end

  describe '#call' do
    context 'with valid parameters' do
      it 'returns a Success monad' do
        service = described_class.new(valid_params)
        result = service.call

        expect(result).to be_success
        expect(result.value!).to be true
      end
    end

    context 'with invalid parameters' do
      it 'returns a Failure monad with validation errors' do
        invalid_params = { external_po_id: nil }
        service = described_class.new(invalid_params)
        result = service.call

        expect(result).to be_failure
        expect(result.failure).to include('external_po_id')
      end
    end
  end

  describe 'validation' do
    context 'external_po_id' do
      it 'is required' do
        params = valid_params.except(:external_po_id)
        service = described_class.new(params)
        service.call

        expect(service.errors[:external_po_id]).to be_present
      end

      it 'must be a string' do
        params = valid_params.merge(external_po_id: 123)
        service = described_class.new(params)
        service.call

        expect(service.errors[:external_po_id]).to be_present
      end

      it 'cannot be empty' do
        params = valid_params.merge(external_po_id: "")
        service = described_class.new(params)
        service.call

        expect(service.errors[:external_po_id]).to be_present
      end
    end

    context 'name' do
      it 'is required' do
        params = valid_params.except(:name)
        service = described_class.new(params)
        service.call

        expect(service.errors[:name]).to be_present
      end

      it 'must be a string' do
        params = valid_params.merge(name: 123)
        service = described_class.new(params)
        service.call

        expect(service.errors[:name]).to be_present
      end

      it 'cannot be empty' do
        params = valid_params.merge(name: "")
        service = described_class.new(params)
        service.call

        expect(service.errors[:name]).to be_present
      end
    end

    context 'email' do
      it 'is required' do
        params = valid_params.except(:email)
        service = described_class.new(params)
        service.call

        expect(service.errors[:email]).to be_present
      end

      it 'must be a valid email format' do
        params = valid_params.merge(email: "invalid-email")
        service = described_class.new(params)
        service.call

        expect(service.errors[:email]).to be_present
      end

      it 'accepts valid email format' do
        params = valid_params.merge(email: "test@example.com")
        service = described_class.new(params)
        result = service.call

        expect(result).to be_success
      end
    end

    context 'shipping_address' do
      it 'is optional' do
        params = valid_params.except(:shipping_address)
        service = described_class.new(params)
        result = service.call

        expect(result).to be_success
      end

      context 'when provided' do
        it 'requires line1' do
          params = valid_params.merge(
            shipping_address: valid_params[:shipping_address].except(:line1)
          )
          service = described_class.new(params)
          service.call

          expect(service.errors[:'shipping_address.line1']).to be_present
        end

        it 'requires city' do
          params = valid_params.merge(
            shipping_address: valid_params[:shipping_address].except(:city)
          )
          service = described_class.new(params)
          service.call

          expect(service.errors[:'shipping_address.city']).to be_present
        end

        it 'requires postal_code' do
          params = valid_params.merge(
            shipping_address: valid_params[:shipping_address].except(:postal_code)
          )
          service = described_class.new(params)
          service.call

          expect(service.errors[:'shipping_address.postal_code']).to be_present
        end

        it 'requires country' do
          params = valid_params.merge(
            shipping_address: valid_params[:shipping_address].except(:country)
          )
          service = described_class.new(params)
          service.call

          expect(service.errors[:'shipping_address.country']).to be_present
        end

        it 'accepts US as country' do
          params = valid_params.merge(
            shipping_address: valid_params[:shipping_address].merge(country: "US")
          )
          service = described_class.new(params)
          result = service.call

          expect(result).to be_success
        end

        it 'accepts CA as country' do
          params = valid_params.merge(
            shipping_address: valid_params[:shipping_address].merge(country: "CA")
          )
          service = described_class.new(params)
          result = service.call

          expect(result).to be_success
        end

        it 'rejects invalid country codes' do
          params = valid_params.merge(
            shipping_address: valid_params[:shipping_address].merge(country: "UK")
          )
          service = described_class.new(params)
          service.call

          expect(service.errors[:'shipping_address.country']).to be_present
        end

        it 'allows line2 to be optional' do
          params = valid_params.merge(
            shipping_address: valid_params[:shipping_address].except(:line2)
          )
          service = described_class.new(params)
          result = service.call

          expect(result).to be_success
        end
      end
    end

    context 'lines' do
      it 'is required' do
        params = valid_params.except(:lines)
        service = described_class.new(params)
        service.call

        expect(service.errors[:lines]).to be_present
      end

      it 'must be an array' do
        params = valid_params.merge(lines: "not an array")
        service = described_class.new(params)
        service.call

        expect(service.errors[:lines]).to be_present
      end

      it 'cannot be empty' do
        params = valid_params.merge(lines: [])
        service = described_class.new(params)
        service.call

        expect(service.errors[:lines]).to be_present
      end

      context 'line items' do
        it 'requires sku for each line' do
          params = valid_params.merge(
            lines: [{ quantity: 1 }]
          )
          service = described_class.new(params)
          service.call

          expect(service.errors[:'lines.0.sku']).to be_present
        end

        it 'requires quantity for each line' do
          params = valid_params.merge(
            lines: [{ sku: "SKU-001" }]
          )
          service = described_class.new(params)
          service.call

          expect(service.errors[:'lines.0.quantity']).to be_present
        end

        it 'requires quantity to be an integer' do
          params = valid_params.merge(
            lines: [{ sku: "SKU-001", quantity: "invalid" }]
          )
          service = described_class.new(params)
          service.call

          expect(service.errors[:'lines.0.quantity']).to be_present
        end

        it 'accepts valid line items' do
          params = valid_params.merge(
            lines: [
              { sku: "SKU-001", quantity: 2 },
              { sku: "SKU-002", quantity: 1 }
            ]
          )
          service = described_class.new(params)
          result = service.call

          expect(result).to be_success
        end
      end
    end

    context 'requested_ship_date' do
      it 'is optional' do
        params = valid_params.except(:requested_ship_date)
        service = described_class.new(params)
        result = service.call

        expect(result).to be_success
      end

      it 'accepts valid date format' do
        params = valid_params.merge(requested_ship_date: "2025-12-31")
        service = described_class.new(params)
        result = service.call

        expect(result).to be_success
      end

      it 'rejects invalid date format' do
        params = valid_params.merge(requested_ship_date: "2025/12/31")
        service = described_class.new(params)
        service.call

        expect(service.errors[:requested_ship_date]).to be_present
      end

      it 'rejects year 0000' do
        params = valid_params.merge(requested_ship_date: "0000-12-31")
        service = described_class.new(params)
        service.call

        expect(service.errors[:requested_ship_date]).to be_present
      end

      it 'rejects invalid month' do
        params = valid_params.merge(requested_ship_date: "2025-13-01")
        service = described_class.new(params)
        service.call

        expect(service.errors[:requested_ship_date]).to be_present
      end

      it 'rejects invalid day' do
        params = valid_params.merge(requested_ship_date: "2025-12-32")
        service = described_class.new(params)
        service.call

        expect(service.errors[:requested_ship_date]).to be_present
      end
    end

    context 'currency' do
      it 'is required' do
        params = valid_params.except(:currency)
        service = described_class.new(params)
        service.call

        expect(service.errors[:currency]).to be_present
      end

      it 'accepts USD' do
        params = valid_params.merge(currency: "USD")
        service = described_class.new(params)
        result = service.call

        expect(result).to be_success
      end

      it 'accepts CAD' do
        params = valid_params.merge(currency: "CAD")
        service = described_class.new(params)
        result = service.call

        expect(result).to be_success
      end

      it 'rejects invalid currency codes' do
        params = valid_params.merge(currency: "EUR")
        service = described_class.new(params)
        service.call

        expect(service.errors[:currency]).to be_present
      end
    end
  end

  describe 'integration scenarios' do
    it 'handles complete valid purchase order' do
      service = described_class.new(valid_params)
      result = service.call

      expect(result).to be_success
      expect(service.errors).to be_empty
    end

    it 'handles minimal valid purchase order' do
      minimal_params = {
        external_po_id: "PO-12345",
        name: "Acme Inc",
        email: "buy@acme.example",
        lines: [{ sku: "SKU-001", quantity: 1 }],
        currency: "USD"
      }
      service = described_class.new(minimal_params)
      result = service.call

      expect(result).to be_success
      expect(service.errors).to be_empty
    end

    it 'collects all validation errors' do
      invalid_params = {
        external_po_id: nil,
        name: nil,
        email: "invalid-email",
        lines: [],
        currency: "EUR"
      }
      service = described_class.new(invalid_params)
      service.call

      expect(service.errors[:external_po_id]).to be_present
      expect(service.errors[:name]).to be_present
      expect(service.errors[:email]).to be_present
      expect(service.errors[:lines]).to be_present
      expect(service.errors[:currency]).to be_present
    end
  end
end
