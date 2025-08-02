require 'rails_helper'

RSpec.describe Api::V1::PurchaseOrdersController, type: :controller do
  describe 'POST #create' do
    let(:valid_params) do
      {
        external_po_id: "PO-12345",
        requested_ship_date: "2025-08-05",
        currency: "USD",
        customer: {
          external_customer_ref: "CUST-998",
          name: "Acme Inc",
          email: "buy@acme.example",
          address: {
            line_1: "1 Main St",
            line_2: "Suite 100",
            city: "New York",
            state: "NY",
            zip: "10001"
          }
        },
        lines: [
          { sku: "SKU-001", quantity: 2 },
          { sku: "SKU-002", quantity: 1 }
        ]
      }
    end

    let(:result_double) { double('result') }

    before do
      allow(PurchaseOrders::Receive).to receive(:call).and_return(result_double)
    end

    context 'when the service succeeds' do
      let(:success_value) do
        {
          customer: {
            id: 1,
            external_customer_ref: "CUST-998",
            name: "Acme Inc"
          },
          purchase_order: {
            id: 1,
            external_po_id: "PO-12345",
            customer_id: 1,
            currency: "USD",
            lines_count: 2
          }
        }
      end

      before do
        allow(result_double).to receive(:success?).and_return(true)
        allow(result_double).to receive(:value).and_return(success_value)
      end

      it 'calls the service with the correct parameters' do
        post :create, params: valid_params

        expect(PurchaseOrders::Receive).to have_received(:call).with(
          hash_including(
            external_po_id: "PO-12345",
            requested_ship_date: "2025-08-05",
            currency: "USD"
          )
        )
      end

      it 'returns the service value with created status' do
        post :create, params: valid_params

        expect(response).to have_http_status(:created)
        expect(JSON.parse(response.body)).to eq(success_value.as_json)
      end
    end

    context 'when the service fails' do
      let(:error_messages) do
        {
          external_po_id: ["can't be blank"],
          email: ["must be a valid email format"],
          lines: ["cannot be empty"]
        }
      end

      before do
        allow(result_double).to receive(:success?).and_return(false)
        allow(result_double).to receive(:failure).and_return(error_messages)
      end

      it 'returns unprocessable entity status' do
        post :create, params: valid_params

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns the error messages in the response' do
        post :create, params: valid_params

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key("errors")
        expect(parsed_response["errors"]).to include("external_po_id")
        expect(parsed_response["errors"]).to include("email")
        expect(parsed_response["errors"]).to include("lines")
        expect(parsed_response["errors"]["external_po_id"]).to include("can't be blank")
        expect(parsed_response["errors"]["email"]).to include("must be a valid email format")
        expect(parsed_response["errors"]["lines"]).to include("cannot be empty")
      end
    end

    context 'with minimal valid parameters' do
      let(:minimal_params) do
        {
          external_po_id: "PO-12345",
          currency: "USD",
          customer: {
            external_customer_ref: "CUST-998",
            name: "Acme Inc",
            email: "buy@acme.example",
            address: {
              line_1: "1 Main St",
              city: "New York",
              state: "NY",
              zip: "10001"
            }
          },
          lines: [
            { sku: "SKU-001", quantity: 1 }
          ]
        }
      end

      before do
        allow(result_double).to receive(:success?).and_return(true)
        allow(result_double).to receive(:value).and_return({})
      end

      it 'handles minimal parameters successfully' do
        post :create, params: minimal_params

        expect(response).to have_http_status(:created)
        expect(PurchaseOrders::Receive).to have_received(:call)
      end
    end

    context 'with missing required parameters' do
      let(:invalid_params) do
        {
          external_po_id: nil,
          currency: "EUR", # Invalid currency
          customer: {
            external_customer_ref: nil,
            name: nil,
            email: "invalid-email",
            address: {
              line_1: nil,
              city: nil,
              state: nil,
              zip: nil
            }
          },
          lines: []
        }
      end

      let(:error_messages) do
        {
          external_po_id: ["can't be blank"],
          currency: ["must be USD or CAD"],
          "customer.external_customer_ref" => ["can't be blank"],
          "customer.name" => ["can't be blank"],
          "customer.email" => ["must be a valid email format"],
          lines: ["cannot be empty"]
        }
      end

      before do
        allow(result_double).to receive(:success?).and_return(false)
        allow(result_double).to receive(:failure).and_return(error_messages)
      end

      it 'returns validation errors' do
        post :create, params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["errors"]).to include("external_po_id")
        expect(parsed_response["errors"]).to include("currency")
        expect(parsed_response["errors"]).to include("customer.external_customer_ref")
        expect(parsed_response["errors"]).to include("customer.name")
        expect(parsed_response["errors"]).to include("customer.email")
        expect(parsed_response["errors"]).to include("lines")
        expect(parsed_response["errors"]["external_po_id"]).to include("can't be blank")
        expect(parsed_response["errors"]["currency"]).to include("must be USD or CAD")
        expect(parsed_response["errors"]["customer.email"]).to include("must be a valid email format")
        expect(parsed_response["errors"]["lines"]).to include("cannot be empty")
      end
    end

    context 'parameter filtering' do
      it 'filters out unpermitted parameters' do
        params_with_extra = valid_params.merge(
          unpermitted_param: "should be ignored",
          customer: valid_params[:customer].merge(
            unpermitted_customer_param: "should be ignored"
          )
        )

        allow(result_double).to receive(:success?).and_return(true)
        allow(result_double).to receive(:value).and_return({})

        post :create, params: params_with_extra

        expect(PurchaseOrders::Receive).to have_received(:call).with(
          hash_excluding(:unpermitted_param, :unpermitted_customer_param)
        )
      end

      it 'converts parameters to hash' do
        allow(result_double).to receive(:success?).and_return(true)
        allow(result_double).to receive(:value).and_return({})

        post :create, params: valid_params

        # Rails converts parameters to string keys, which is expected behavior
        expect(PurchaseOrders::Receive).to have_received(:call).with(
          hash_including(
            "external_po_id" => "PO-12345",
            "currency" => "USD"
          )
        )
      end
    end

    context 'edge cases' do
      it 'handles empty request body gracefully' do
        allow(result_double).to receive(:success?).and_return(false)
        allow(result_double).to receive(:failure).and_return({})

        post :create, params: {}

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ "errors" => {} })
      end

      it 'handles nil parameters gracefully' do
        allow(result_double).to receive(:success?).and_return(false)
        allow(result_double).to receive(:failure).and_return({})

        post :create, params: nil

        expect(response).to have_http_status(:unprocessable_entity)
        expect(JSON.parse(response.body)).to eq({ "errors" => {} })
      end
    end
  end
end