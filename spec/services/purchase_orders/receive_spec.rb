require 'rails_helper'

RSpec.describe PurchaseOrders::Receive do
  # Base valid parameters with stringified keys that match the service schema
  let(:valid_params) do
    {
      "external_po_id" => "PO-12345",
      "customer" => {
        "external_customer_ref" => "CUST-998",
        "name" => "Acme Inc",
        "email" => "buy@acme.example",
        "shipping_address" => {
          "line1" => "1 Main St",
          "line2" => "Suite 100",
          "city" => "New York",
          "postal_code" => "10001",
          "country" => "US"
        }
      },
      "lines" => [
        { "sku" => "SKU-001", "quantity" => 2 },
        { "sku" => "SKU-002", "quantity" => 1 }
      ],
      "requested_ship_date" => "2025-08-05",
      "currency" => "USD"
    }
  end

  # Helper method to create modified params for different test scenarios
  def params_with(overrides = {})
    deep_merge(valid_params, overrides)
  end

  # Helper method for deep merging hashes
  def deep_merge(hash1, hash2)
    hash1.merge(hash2) do |key, val1, val2|
      if val1.is_a?(Hash) && val2.is_a?(Hash)
        deep_merge(val1, val2)
      else
        val2
      end
    end
  end

  describe '.call' do
    it 'creates a new instance and calls it' do
      result = described_class.call(valid_params)

      expect(result).to be_success
      expect(result.value).to be_a(Hash)
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
      it 'returns a Success result' do
        service = described_class.new(valid_params)
        result = service.call

        expect(result).to be_success
        expect(result.value).to be_a(Hash)
        expect(result.errors).to be_empty
      end

      it 'creates customer and purchase order records' do
        service = described_class.new(valid_params)
        result = service.call

        expect(result).to be_success
        expect(result.value["customer"]["external_customer_ref"]).to eq("CUST-998")
        expect(result.value["purchase_order"]["external_po_id"]).to eq("PO-12345")
      end
    end

    context 'with invalid parameters' do
      it 'returns a Failure result with validation errors' do
        invalid_params = params_with("external_po_id" => nil)
        service = described_class.new(invalid_params)
        result = service.call

        expect(result).not_to be_success
        expect(result.errors).to include("external_po_id")
      end
    end
  end

  describe 'validation' do
    context 'external_po_id' do
      it 'is required' do
        params = valid_params.deep_dup
        params.delete("external_po_id")
        service = described_class.new(params)
        result = service.call

        expect(result.errors["external_po_id"]).to be_present
      end

      it 'must be a string' do
        params = params_with("external_po_id" => 123)
        service = described_class.new(params)
        result = service.call

        expect(result.errors["external_po_id"]).to be_present
      end

      it 'cannot be empty' do
        params = params_with("external_po_id" => "")
        service = described_class.new(params)
        result = service.call

        expect(result.errors["external_po_id"]).to be_present
      end
    end

    context 'customer' do
      it 'is required' do
        params = valid_params.deep_dup
        params.delete("customer")
        service = described_class.new(params)
        result = service.call

        expect(result.errors["customer"]).to be_present
      end

      context 'external_customer_ref' do
        it 'is required' do
          params = valid_params.deep_dup
          params["customer"].delete("external_customer_ref")
          service = described_class.new(params)
          result = service.call

          expect(result.errors["customer.external_customer_ref"]).to be_present
        end

        it 'must be a string' do
          params = params_with("customer" => valid_params["customer"].merge("external_customer_ref" => 123))
          service = described_class.new(params)
          result = service.call

          expect(result.errors["customer.external_customer_ref"]).to be_present
        end
      end

      context 'name' do
        it 'is required' do
          params = valid_params.deep_dup
          params["customer"].delete("name")
          service = described_class.new(params)
          result = service.call

          expect(result.errors["customer.name"]).to be_present
        end

        it 'must be a string' do
          params = params_with("customer" => valid_params["customer"].merge("name" => 123))
          service = described_class.new(params)
          result = service.call

          expect(result.errors["customer.name"]).to be_present
        end

        it 'cannot be empty' do
          params = params_with("customer" => valid_params["customer"].merge("name" => ""))
          service = described_class.new(params)
          result = service.call

          expect(result.errors["customer.name"]).to be_present
        end
      end

      context 'email' do
        it 'is required' do
          params = valid_params.deep_dup
          params["customer"].delete("email")
          service = described_class.new(params)
          result = service.call

          expect(result.errors["customer.email"]).to be_present
        end

        it 'must be a valid email format' do
          params = params_with("customer" => valid_params["customer"].merge("email" => "invalid-email"))
          service = described_class.new(params)
          result = service.call

          expect(result.errors["customer.email"]).to be_present
        end

        it 'accepts valid email format' do
          params = params_with("customer" => valid_params["customer"].merge("email" => "test@example.com"))
          service = described_class.new(params)
          result = service.call

          expect(result).to be_success
        end
      end

      context 'shipping_address' do
        it 'is optional' do
          params = valid_params.deep_dup
          params["customer"].delete("shipping_address")
          service = described_class.new(params)
          result = service.call

          expect(result).to be_success
        end

        context 'when provided' do
          it 'requires line1' do
            params = valid_params.deep_dup
            params["customer"]["shipping_address"].delete("line1")
            service = described_class.new(params)
            result = service.call

            expect(result.errors["customer.shipping_address.line1"]).to be_present
          end

          it 'requires city' do
            params = valid_params.deep_dup
            params["customer"]["shipping_address"].delete("city")
            service = described_class.new(params)
            result = service.call

            expect(result.errors["customer.shipping_address.city"]).to be_present
          end

          it 'requires postal_code' do
            params = valid_params.deep_dup
            params["customer"]["shipping_address"].delete("postal_code")
            service = described_class.new(params)
            result = service.call

            expect(result.errors["customer.shipping_address.postal_code"]).to be_present
          end

          it 'requires country' do
            params = valid_params.deep_dup
            params["customer"]["shipping_address"].delete("country")
            service = described_class.new(params)
            result = service.call

            expect(result.errors["customer.shipping_address.country"]).to be_present
          end

          it 'accepts US as country' do
            params = params_with("customer" => {
              **valid_params["customer"],
              "shipping_address" => valid_params["customer"]["shipping_address"].merge("country" => "US")
            })
            service = described_class.new(params)
            result = service.call

            expect(result).to be_success
          end

          it 'accepts CA as country' do
            params = params_with("customer" => {
              **valid_params["customer"],
              "shipping_address" => valid_params["customer"]["shipping_address"].merge("country" => "CA")
            })
            service = described_class.new(params)
            result = service.call

            expect(result).to be_success
          end

          it 'rejects invalid country codes' do
            params = params_with("customer" => {
              **valid_params["customer"],
              "shipping_address" => valid_params["customer"]["shipping_address"].merge("country" => "UK")
            })
            service = described_class.new(params)
            result = service.call

            expect(result.errors["customer.shipping_address.country"]).to be_present
          end

          it 'allows line2 to be optional' do
            params = valid_params.deep_dup
            params["customer"]["shipping_address"].delete("line2")
            service = described_class.new(params)
            result = service.call

            expect(result).to be_success
          end
        end
      end
    end

    context 'lines' do
      it 'is required' do
        params = valid_params.deep_dup
        params.delete("lines")
        service = described_class.new(params)
        result = service.call

        expect(result.errors["lines"]).to be_present
      end

      it 'must be an array' do
        params = params_with("lines" => "not an array")
        service = described_class.new(params)
        result = service.call

        expect(result.errors["lines"]).to be_present
      end

      it 'cannot be empty' do
        params = params_with("lines" => [])
        service = described_class.new(params)
        result = service.call

        expect(result.errors["lines"]).to be_present
      end

      context 'line items' do
        it 'requires sku for each line' do
          params = params_with("lines" => [{ "quantity" => 1 }])
          service = described_class.new(params)
          result = service.call

          expect(result.errors["lines.0.sku"]).to be_present
        end

        it 'requires quantity for each line' do
          params = params_with("lines" => [{ "sku" => "SKU-001" }])
          service = described_class.new(params)
          result = service.call

          expect(result.errors["lines.0.quantity"]).to be_present
        end

        it 'requires quantity to be an integer' do
          params = params_with("lines" => [{ "sku" => "SKU-001", "quantity" => "invalid" }])
          service = described_class.new(params)
          result = service.call

          expect(result.errors["lines.0.quantity"]).to be_present
        end

        it 'accepts valid line items' do
          params = params_with("lines" => [
            { "sku" => "SKU-001", "quantity" => 2 },
            { "sku" => "SKU-002", "quantity" => 1 }
          ])
          service = described_class.new(params)
          result = service.call

          expect(result).to be_success
        end
      end
    end

    context 'requested_ship_date' do
      it 'is optional' do
        params = valid_params.deep_dup
        params.delete("requested_ship_date")
        service = described_class.new(params)
        result = service.call

        expect(result).to be_success
      end

      it 'accepts valid date format' do
        params = params_with("requested_ship_date" => "2025-12-31")
        service = described_class.new(params)
        result = service.call

        expect(result).to be_success
      end

      it 'rejects invalid date format' do
        params = params_with("requested_ship_date" => "2025/12/31")
        service = described_class.new(params)
        result = service.call

        expect(result.errors["requested_ship_date"]).to be_present
      end

      it 'rejects year 0000' do
        params = params_with("requested_ship_date" => "0000-12-31")
        service = described_class.new(params)
        result = service.call

        expect(result.errors["requested_ship_date"]).to be_present
      end

      it 'rejects invalid month' do
        params = params_with("requested_ship_date" => "2025-13-01")
        service = described_class.new(params)
        result = service.call

        expect(result.errors["requested_ship_date"]).to be_present
      end

      it 'rejects invalid day' do
        params = params_with("requested_ship_date" => "2025-12-32")
        service = described_class.new(params)
        result = service.call

        expect(result.errors["requested_ship_date"]).to be_present
      end
    end

    context 'currency' do
      it 'is required' do
        params = valid_params.deep_dup
        params.delete("currency")
        service = described_class.new(params)
        result = service.call

        expect(result.errors["currency"]).to be_present
      end

      it 'accepts USD' do
        params = params_with("currency" => "USD")
        service = described_class.new(params)
        result = service.call

        expect(result).to be_success
      end

      it 'accepts CAD' do
        params = params_with("currency" => "CAD")
        service = described_class.new(params)
        result = service.call

        expect(result).to be_success
      end

      it 'rejects invalid currency codes' do
        params = params_with("currency" => "EUR")
        service = described_class.new(params)
        result = service.call

        expect(result.errors["currency"]).to be_present
      end
    end
  end

  describe 'integration scenarios' do
    it 'handles complete valid purchase order' do
      service = described_class.new(valid_params)
      result = service.call

      expect(result).to be_success
      expect(result.errors).to be_empty
    end

    it 'handles minimal valid purchase order' do
      minimal_params = {
        "external_po_id" => "PO-12345",
        "customer" => {
          "external_customer_ref" => "CUST-998",
          "name" => "Acme Inc",
          "email" => "buy@acme.example"
        },
        "lines" => [{ "sku" => "SKU-001", "quantity" => 1 }],
        "currency" => "USD"
      }
      service = described_class.new(minimal_params)
      result = service.call

      expect(result).to be_success
      expect(result.errors).to be_empty
    end

    it 'collects all validation errors' do
      invalid_params = {
        "external_po_id" => nil,
        "customer" => {
          "external_customer_ref" => nil,
          "name" => nil,
          "email" => "invalid-email"
        },
        "lines" => [],
        "currency" => "EUR"
      }
      service = described_class.new(invalid_params)
      result = service.call

      expect(result.errors["external_po_id"]).to be_present
      expect(result.errors["customer.external_customer_ref"]).to be_present
      expect(result.errors["customer.name"]).to be_present
      expect(result.errors["customer.email"]).to be_present
      expect(result.errors["lines"]).to be_present
      expect(result.errors["currency"]).to be_present
    end
  end
end
