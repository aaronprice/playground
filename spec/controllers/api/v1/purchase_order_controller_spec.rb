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

    context 'when the service succeeds' do
      it 'returns the service value with created status' do
        post :create, params: valid_params

        expect(response).to have_http_status(:created)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key("customer")
        expect(parsed_response).to have_key("purchase_order")
        expect(parsed_response["customer"]).to have_key("external_customer_ref")
        expect(parsed_response["customer"]).to have_key("name")
        expect(parsed_response["purchase_order"]).to have_key("external_po_id")
        expect(parsed_response["purchase_order"]).to have_key("currency")
        expect(parsed_response["purchase_order"]).to have_key("lines_count")
      end
    end

    context 'when the service fails' do
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

      it 'returns unprocessable entity status' do
        post :create, params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
      end

      it 'returns the error messages in the response' do
        post :create, params: invalid_params

        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key("errors")
        expect(parsed_response["errors"]).to include("external_po_id")
        expect(parsed_response["errors"]).to include("currency")
        expect(parsed_response["errors"]).to include("customer.external_customer_ref")
        expect(parsed_response["errors"]).to include("customer.name")
        expect(parsed_response["errors"]).to include("customer.email")
        expect(parsed_response["errors"]).to include("lines")
        expect(parsed_response["errors"]["external_po_id"]).to include("must be filled")
        expect(parsed_response["errors"]["currency"]).to include("is in invalid format")
        expect(parsed_response["errors"]["customer.email"]).to include("is in invalid format")
        expect(parsed_response["errors"]["lines"]).to include("is missing")
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

      it 'handles minimal parameters successfully' do
        post :create, params: minimal_params

        expect(response).to have_http_status(:created)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key("customer")
        expect(parsed_response).to have_key("purchase_order")
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

      it 'returns validation errors' do
        post :create, params: invalid_params

        expect(response).to have_http_status(:unprocessable_content)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["errors"]).to include("external_po_id")
        expect(parsed_response["errors"]).to include("currency")
        expect(parsed_response["errors"]).to include("customer.external_customer_ref")
        expect(parsed_response["errors"]).to include("customer.name")
        expect(parsed_response["errors"]).to include("customer.email")
        expect(parsed_response["errors"]).to include("lines")
        expect(parsed_response["errors"]["external_po_id"]).to include("must be filled")
        expect(parsed_response["errors"]["currency"]).to include("is in invalid format")
        expect(parsed_response["errors"]["customer.external_customer_ref"]).to include("must be filled")
        expect(parsed_response["errors"]["customer.name"]).to include("must be filled")
        expect(parsed_response["errors"]["customer.email"]).to include("is in invalid format")
        expect(parsed_response["errors"]["lines"]).to include("is missing")
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

        post :create, params: params_with_extra

        expect(response).to have_http_status(:created)
        # The service should still succeed despite extra parameters being filtered
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key("customer")
        expect(parsed_response).to have_key("purchase_order")
      end
    end

    context 'edge cases' do
      it 'handles empty request body gracefully' do
        post :create, params: {}

        expect(response).to have_http_status(:unprocessable_content)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key("errors")
        expect(parsed_response["errors"]).to include("external_po_id")
        expect(parsed_response["errors"]).to include("currency")
        expect(parsed_response["errors"]).to include("customer")
        expect(parsed_response["errors"]).to include("lines")
      end

      it 'handles nil parameters gracefully' do
        post :create, params: nil

        expect(response).to have_http_status(:unprocessable_content)
        parsed_response = JSON.parse(response.body)
        expect(parsed_response).to have_key("errors")
        expect(parsed_response["errors"]).to include("external_po_id")
        expect(parsed_response["errors"]).to include("currency")
        expect(parsed_response["errors"]).to include("customer")
        expect(parsed_response["errors"]).to include("lines")
      end
    end
  end
end